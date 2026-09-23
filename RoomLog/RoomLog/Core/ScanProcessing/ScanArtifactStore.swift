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

    init(userDefaults: UserDefaults = .standard, baseDirectory: URL? = nil) {
        self.userDefaults = userDefaults
        let base = baseDirectory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.directory = base.appendingPathComponent("ScanUploads", isDirectory: true)
    }

    // MARK: - Zip 위치

    /// zip 생성 위치 발급. 디렉토리가 없으면 만들고 iCloud 백업에서 제외한다.
    func zipDestinationURL() -> URL {
        ensureDirectory()
        return directory.appendingPathComponent("\(UUID().uuidString).zip")
    }

    // MARK: - 단계 기록

    func save(_ stage: PersistedStage) {
        guard let data = try? JSONEncoder().encode(stage) else { return }
        userDefaults.set(data, forKey: Self.stageKey)
    }

    /// 기록과 기록된 zip 파일을 함께 폐기한다 (완료·취소·재시도 불가 실패).
    func clear() {
        if case .uploadReady(let fileName, _) = loadStage() {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
        }
        userDefaults.removeObject(forKey: Self.stageKey)
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

    /// 기록에 없는 zip 파일 청소 — 압축 중 크래시 파편, 단계 전환 후 잔여물.
    func sweepOrphans() {
        let recordedFileName: String? = if case .uploadReady(let fileName, _) = loadStage() {
            fileName
        } else {
            nil
        }
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return }
        for file in files where file.lastPathComponent != recordedFileName {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Private

    private func loadStage() -> PersistedStage? {
        guard let data = userDefaults.data(forKey: Self.stageKey) else { return nil }
        return try? JSONDecoder().decode(PersistedStage.self, from: data)
    }

    private func ensureDirectory() {
        guard !FileManager.default.fileExists(atPath: directory.path) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var url = directory
        try? url.setResourceValues(values)
    }
}
