//
//  ScanArtifactStoreTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 9/23/26.
//

import Testing
import Foundation
@testable import RoomLog

final class ScanArtifactStoreTests {

    /// 테스트마다 고유한 suite·디렉토리를 사용해 병렬 실행 간 간섭을 차단
    private let suiteName: String
    private let defaults: UserDefaults
    private let baseDirectory: URL
    private let legacyDocuments: URL
    private let sut: ScanArtifactStore

    init() throws {
        suiteName = "ScanArtifactStoreTests-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        legacyDocuments = baseDirectory.appendingPathComponent("Documents", isDirectory: true)
        sut = ScanArtifactStore(
            userDefaults: defaults,
            baseDirectory: baseDirectory,
            legacyDocumentsDirectory: legacyDocuments
        )
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: baseDirectory)
    }

    /// zip 파일을 흉내 내는 더미 파일 생성
    private func makeZip() throws -> URL {
        let url = sut.zipDestinationURL()
        try Data("zip".utf8).write(to: url)
        return url
    }

    @Test func zipDestinationURL은_디렉토리를_만들고_zip경로를_발급한다() throws {
        let url = try makeZip()

        #expect(url.pathExtension == "zip")
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test func uploadReady_저장후_복원하면_zip경로가_돌아온다() throws {
        let url = try makeZip()

        sut.save(.uploadReady(zipFileName: url.lastPathComponent, houseId: 5))

        #expect(sut.restore() == .uploadRetry(zipURL: url, houseId: 5))
    }

    @Test func uploadReady인데_zip파일이_없으면_죽은기록을_정리하고_nil이다() {
        sut.save(.uploadReady(zipFileName: "ghost.zip", houseId: 5))

        #expect(sut.restore() == nil)
        // 기록 자체가 정리됐는지 재확인 — 남아 있으면 매 실행마다 파일 검사를 반복하게 된다
        #expect(sut.restore() == nil)
    }

    @Test func polling_저장후_복원하면_polling이다() {
        sut.save(.polling(scanId: 42, houseId: 5))

        #expect(sut.restore() == .polling(scanId: 42, houseId: 5))
    }

    @Test func 단계전환은_원자적이다_polling저장이_uploadReady를_대체한다() throws {
        let url = try makeZip()
        sut.save(.uploadReady(zipFileName: url.lastPathComponent, houseId: 5))

        sut.save(.polling(scanId: 42, houseId: 5))

        #expect(sut.restore() == .polling(scanId: 42, houseId: 5))
    }

    @Test func clear는_기록과_zip파일을_함께_지운다() throws {
        let url = try makeZip()
        sut.save(.uploadReady(zipFileName: url.lastPathComponent, houseId: 5))

        sut.clear()

        #expect(sut.restore() == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func markUploaded는_polling으로_전환하고_업로드된_zip을_지운다() throws {
        let url = try makeZip()
        sut.save(.uploadReady(zipFileName: url.lastPathComponent, houseId: 5))

        sut.markUploaded(scanId: 42, houseId: 5)

        #expect(sut.restore() == .polling(scanId: 42, houseId: 5))
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func discard는_기록되지_않은_zip만_지우고_기록은_건드리지_않는다() throws {
        let recorded = try makeZip()
        let fragment = try makeZip()
        sut.save(.uploadReady(zipFileName: recorded.lastPathComponent, houseId: 5))

        sut.discard(fragment)

        #expect(!FileManager.default.fileExists(atPath: fragment.path))
        #expect(sut.restore() == .uploadRetry(zipURL: recorded, houseId: 5))
    }

    @Test func sweepOrphans는_기록된_zip만_남긴다() throws {
        let recorded = try makeZip()
        let orphan1 = try makeZip()
        let orphan2 = try makeZip()
        sut.save(.uploadReady(zipFileName: recorded.lastPathComponent, houseId: 5))

        sut.sweepOrphans()

        #expect(FileManager.default.fileExists(atPath: recorded.path))
        #expect(!FileManager.default.fileExists(atPath: orphan1.path))
        #expect(!FileManager.default.fileExists(atPath: orphan2.path))
    }

    // MARK: - 캡처 데이터셋

    /// 구버전 인코더가 만들던 형태의 데이터셋 흉내 (odometry.csv는 인코더가 생성 즉시 만든다)
    private func makeLegacyItem(named name: String, withOdometry: Bool) throws -> URL {
        let url = legacyDocuments.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        if withOdometry {
            try Data().write(to: url.appendingPathComponent("odometry.csv"))
        }
        return url
    }

    @Test func makeDatasetDirectory는_매번_새_디렉토리를_만든다() throws {
        let first = try sut.makeDatasetDirectory()
        let second = try sut.makeDatasetDirectory()

        #expect(first != second)
        #expect(FileManager.default.fileExists(atPath: first.path))
        #expect(first.path.hasPrefix(baseDirectory.path), "Documents가 아닌 스토어 관리 위치에 만들어야 합니다")
    }

    @Test func 이미_존재하는_데이터셋_디렉토리에도_백업_제외를_적용한다() throws {
        // 과거 실행에서 속성 설정이 실패한 상황: 디렉토리만 있고 백업 제외 속성이 없다
        let datasetsDir = baseDirectory.appendingPathComponent("ScanDatasets", isDirectory: true)
        try FileManager.default.createDirectory(at: datasetsDir, withIntermediateDirectories: true)

        _ = try sut.makeDatasetDirectory()

        let values = try datasetsDir.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }

    @Test func sweepOrphans는_남은_데이터셋을_전부_지운다() throws {
        let dataset = try sut.makeDatasetDirectory()
        try Data("frame".utf8).write(to: dataset.appendingPathComponent("odometry.csv"))

        sut.sweepOrphans()

        #expect(!FileManager.default.fileExists(atPath: dataset.path))
    }

    @Test func sweepOrphans는_구버전_Documents_데이터셋만_골라_지운다() throws {
        let legacy = try makeLegacyItem(named: "a1b2c3d4e5", withOdometry: true)
        let hexWithoutMarker = try makeLegacyItem(named: "0123456789", withOdometry: false)
        // 소문자 항목과 대소문자만 다른 이름은 금물 — 시뮬레이터의 케이스 비구분 APFS에서 같은 항목으로 충돌한다
        let uppercaseHex = try makeLegacyItem(named: "F9E8D7C6B5", withOdometry: true)
        let otherName = try makeLegacyItem(named: "MyFolder", withOdometry: true)

        sut.sweepOrphans()

        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        #expect(FileManager.default.fileExists(atPath: hexWithoutMarker.path), "데이터셋 표식이 없으면 지우면 안 됩니다")
        #expect(FileManager.default.fileExists(atPath: uppercaseHex.path), "구버전 이름 규칙(소문자 hex)이 아니면 지우면 안 됩니다")
        #expect(FileManager.default.fileExists(atPath: otherName.path))
    }

    @Test func 컨테이너_경로가_바뀌어도_파일명_기록으로_복원된다() throws {
        // 앱 업데이트로 컨테이너 UUID가 바뀌는 상황: 같은 기록, 다른 베이스 경로
        let url = try makeZip()
        sut.save(.uploadReady(zipFileName: url.lastPathComponent, houseId: 5))

        let movedBase = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(suiteName)-moved", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: movedBase) }
        let movedDir = movedBase.appendingPathComponent("ScanUploads", isDirectory: true)
        try FileManager.default.createDirectory(at: movedDir, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: url, to: movedDir.appendingPathComponent(url.lastPathComponent))

        let movedStore = ScanArtifactStore(userDefaults: defaults, baseDirectory: movedBase)
        guard case .uploadRetry(let zipURL, let houseId) = movedStore.restore() else {
            Issue.record("새 컨테이너에서도 uploadRetry로 복원돼야 합니다")
            return
        }
        #expect(houseId == 5)
        #expect(zipURL.path.hasPrefix(movedBase.path), "URL은 현재 컨테이너 기준으로 재조립돼야 합니다")
    }
}
