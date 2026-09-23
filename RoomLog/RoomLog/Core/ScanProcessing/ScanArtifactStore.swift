//
//  ScanArtifactStore.swift
//  RoomLog
//
//  Created by Doyeon Kim on 9/23/26.
//

import Foundation

/// 진행 단계를 Codable enum **단일 레코드**로 저장하므로 업로드 성공 시
/// uploadReady → polling 전환이 원자적이다 — 어중간한 조합이 존재할 수 없다.
/// 기록에는 파일명만 저장한다: 앱 컨테이너 UUID가 업데이트마다 바뀌므로 절대경로는 금물.
///
/// init 기본 인자로 쓰이므로 nonisolated — UserDefaults·FileManager는 스레드 안전하다.
nonisolated struct ScanArtifactStore {

    /// 디스크에 저장되는 진행 단계.
    enum PersistedStage: Codable, Equatable {
        /// zip 완성 ~ 업로드 성공 전. 재실행 시 업로드 재시도 상태로 복원된다.
        case uploadReady(zipFileName: String, houseId: Int)
        /// 업로드 성공 이후. 재실행 시 폴링 재개로 복원된다.
        case polling(scanId: Int, houseId: Int)
    }

    /// 복원 결과. 파일명 기록을 현재 컨테이너 기준 URL로 되살려 돌려준다.
    enum RestoredWork: Equatable {
        case uploadRetry(zipURL: URL, houseId: Int)
        case polling(scanId: Int, houseId: Int)
    }

    private static let stageKey = "ScanArtifact_stage"

    private let userDefaults: UserDefaults
    private let directory: URL
    private let datasetsDirectory: URL
    private let legacyDatasetsDirectory: URL

    /// - Parameter legacyDocumentsDirectory: 구버전이 데이터셋을 만들던 위치. 테스트에서 실제 Documents를 건드리지 않도록 주입한다.
    init(userDefaults: UserDefaults = .standard, baseDirectory: URL? = nil, legacyDocumentsDirectory: URL? = nil) {
        self.userDefaults = userDefaults
        let base = baseDirectory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.directory = base.appendingPathComponent("ScanUploads", isDirectory: true)
        self.datasetsDirectory = base.appendingPathComponent("ScanDatasets", isDirectory: true)
        self.legacyDatasetsDirectory = legacyDocumentsDirectory ?? URL.documentsDirectory
    }

    // MARK: - Zip 위치

    /// zip 생성 위치 발급. 디렉토리가 없으면 만들고 iCloud 백업에서 제외한다.
    func zipDestinationURL() -> URL {
        ensureDirectory(directory)
        return directory.appendingPathComponent("\(UUID().uuidString).zip")
    }

    // MARK: - 캡처 데이터셋

    /// 촬영 데이터셋 디렉토리 발급. 데이터셋은 zip 완성 즉시 삭제되므로
    /// 재실행 시점에 남아 있는 것은 전부 고아다 — `sweepOrphans`가 통째로 청소한다.
    func makeDatasetDirectory() throws -> URL {
        ensureDirectory(datasetsDirectory)
        let url = datasetsDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        log("데이터셋 생성 \(url.lastPathComponent.prefix(8)) → 현재 \(contents(of: datasetsDirectory).count)개")
        return url
    }

    /// 다 쓴(zip 완성) 또는 버려진(변환 없이 종료) 데이터셋 삭제
    func discardDataset(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        log("데이터셋 삭제 \(url.lastPathComponent.prefix(8)) → 현재 \(contents(of: datasetsDirectory).count)개")
    }

    // MARK: - 단계 기록

    func save(_ stage: PersistedStage) {
        guard let data = try? JSONEncoder().encode(stage) else { return }
        userDefaults.set(data, forKey: Self.stageKey)
    }

    /// 업로드 성공 — 단계를 polling으로 원자 전환한 뒤 다 쓴 zip을 지운다.
    /// 전환과 삭제 사이에 앱이 죽어도 남은 zip은 다음 실행의 `sweepOrphans`가 청소한다.
    func markUploaded(scanId: Int, houseId: Int) {
        let uploadedFileName = recordedZipFileName()
        save(.polling(scanId: scanId, houseId: houseId))
        if let uploadedFileName {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(uploadedFileName))
        }
    }

    /// 기록과 기록된 zip 파일을 함께 폐기한다 (완료·취소·재시도 불가 실패).
    func clear() {
        if let fileName = recordedZipFileName() {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
        }
        userDefaults.removeObject(forKey: Self.stageKey)
    }

    /// 기록되기 전의 zip 폐기 (압축 실패·취소로 생긴 파편).
    func discard(_ zipURL: URL) {
        try? FileManager.default.removeItem(at: zipURL)
    }

    // MARK: - 복원·청소

    /// 저장된 단계를 복원한다. uploadReady인데 zip 파일이 사라졌으면
    /// (유저의 저장공간 정리 등) 죽은 기록이므로 정리하고 nil을 돌려준다.
    func restore() -> RestoredWork? {
        switch loadStage() {
        case .polling(let scanId, let houseId):
            return .polling(scanId: scanId, houseId: houseId)
        case .uploadReady(let fileName, let houseId):
            let zipURL = directory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: zipURL.path) else {
                userDefaults.removeObject(forKey: Self.stageKey)
                return nil
            }
            return .uploadRetry(zipURL: zipURL, houseId: houseId)
        case nil:
            return nil
        }
    }

    /// 재실행 시점의 고아 청소.
    /// - 기록에 없는 zip: 압축 중 크래시 파편, 단계 전환 후 잔여물
    /// - 데이터셋 전부: 압축 중 종료·변환 없이 버려진 것
    /// - 구버전이 `Documents`에 남긴 데이터셋
    func sweepOrphans() {
        let recordedFileName = recordedZipFileName()
        let orphanZips = contents(of: directory).filter { $0.lastPathComponent != recordedFileName }
        let datasets = contents(of: datasetsDirectory)
        let legacyDatasets = contents(of: legacyDatasetsDirectory).filter(isLegacyDataset)
        for item in orphanZips + datasets + legacyDatasets {
            try? FileManager.default.removeItem(at: item)
        }
        log("고아 청소 — zip \(orphanZips.count)개, 데이터셋 \(datasets.count)개, 구버전 Documents \(legacyDatasets.count)개")
    }

    // MARK: - Private

    private func loadStage() -> PersistedStage? {
        guard let data = userDefaults.data(forKey: Self.stageKey) else { return nil }
        return try? JSONDecoder().decode(PersistedStage.self, from: data)
    }

    private func recordedZipFileName() -> String? {
        guard case .uploadReady(let fileName, _) = loadStage() else { return nil }
        return fileName
    }

    private func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[ScanArtifact] \(message())")
        #endif
    }

    private func contents(of directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    }

    /// 구버전 데이터셋 판별. Documents의 다른 파일을 지우지 않도록 보수적으로 본다 —
    /// 이름이 10자리 소문자 hex(UUID SHA256 앞 5바이트)이고, 인코더가 생성 즉시 만드는 `odometry.csv`가 있어야 한다.
    private func isLegacyDataset(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        guard name.count == 10, name.allSatisfy({ $0.isHexDigit && !$0.isUppercase }) else { return false }
        return FileManager.default.fileExists(atPath: url.appendingPathComponent("odometry.csv").path)
    }

    private func ensureDirectory(_ directory: URL) {
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        // 백업 제외는 매번 다시 적용한다 (멱등) — 과거 설정 실패로 속성이 빠진 기존 디렉토리도 복구된다
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var url = directory
        try? url.setResourceValues(values)
    }
}
