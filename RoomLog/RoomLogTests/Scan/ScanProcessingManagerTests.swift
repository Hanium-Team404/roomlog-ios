//
//  ScanProcessingManagerTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Testing
import Foundation
@testable import RoomLog
internal import SwiftUI

@MainActor
final class ScanProcessingManagerTests {

    private let mockRepo: MockScanRepository
    /// 테스트마다 고유한 suite·디렉토리를 사용해 호스트 앱 오염과 병렬 실행 간 간섭을 차단
    private let suiteName: String
    private let defaults: UserDefaults
    private let tempDirectory: URL
    private let store: ScanArtifactStore
    private let sut: ScanProcessingManager

    init() throws {
        suiteName = "ScanProcessingManagerTests-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        mockRepo = MockScanRepository()
        store = ScanArtifactStore(userDefaults: defaults, baseDirectory: tempDirectory)
        sut = ScanProcessingManager(
            pollConfig: .init(interval: .milliseconds(50)),
            artifactStore: store
        )
        sut.configure(scanRepository: mockRepo)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    /// 조건이 충족될 때까지 폴링 대기. 충족 즉시 반환하므로 고정 sleep과 달리
    /// CI 부하에 따른 flakiness 없이 빠르게 끝난다. 타임아웃 시 Issue를 기록한다.
    private func waitUntil(
        timeout: Duration = .seconds(2),
        _ condition: () -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while !condition() {
            if clock.now >= deadline {
                Issue.record("waitUntil 타임아웃: \(timeout) 내에 조건이 충족되지 않았습니다")
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    // MARK: - resumePolling (폴링 재개)

    @Test func resumePolling_호출시_polling_상태가_된다() {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.resumePolling(scanId: 100, houseId: 1)

        #expect(sut.activeScan?.scanId == 100)
        #expect(sut.activeScan?.houseId == 1)
        #expect(sut.activeScan?.phase == .polling)
        // 시동된 폴링 루프 정리 (안 하면 maxAttempts 소진까지 백그라운드에서 계속 돈다)
        sut.clear()
    }

    // MARK: - cancel

    @Test func cancel_호출시_activeScan이_nil이_된다() {
        sut.resumePolling(scanId: 100, houseId: 1)

        sut.cancel()

        #expect(sut.activeScan == nil)
        #expect(store.restore() == nil)
    }

    // MARK: - clear

    @Test func clear_호출시_상태가_초기화된다() {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 1, houseId: 1,
                phase: .completed(fileURL: URL(fileURLWithPath: "/tmp/test.ply"))
            )
        )

        sut.clear()

        #expect(sut.activeScan == nil)
    }

    // MARK: - completedScan

    @Test func completedScan_완료된_스캔이_있으면_반환한다() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.ply")
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 1, houseId: 5, phase: .completed(fileURL: fileURL))
        )

        let result = sut.completedScan(for: 5)

        #expect(result?.scanId == 1)
    }

    @Test func completedScan_다른_houseId면_nil을_반환한다() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.ply")
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 1, houseId: 5, phase: .completed(fileURL: fileURL))
        )

        let result = sut.completedScan(for: 99)

        #expect(result == nil)
    }

    // MARK: - isProcessing

    @Test func isProcessing_polling중이면_true를_반환한다() {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 1, houseId: 3, phase: .polling)
        )

        #expect(sut.isProcessing(for: 3))
    }

    @Test func isProcessing_completed면_false를_반환한다() {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 1, houseId: 3,
                phase: .completed(fileURL: URL(fileURLWithPath: "/tmp/test.ply"))
            )
        )

        #expect(!sut.isProcessing(for: 3))
    }

    // MARK: - handleScenePhase

    @Test func handleScenePhase_background시_폴링이_일시정지된다() async throws {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.handleScenePhase(.background)
        sut.resumePolling(scanId: 1, houseId: 1)

        // 파킹을 직접 관측 — 고정 sleep은 루프가 돌기 전의 0회를 '정지'로 오판(false-pass)할 수 있다
        try await waitUntil { sut.isParked }

        #expect(mockRepo.getScanStatusCallCount == 0)
        // 파킹된 폴링 루프를 깨워서 정리 (안 하면 continuation에 매달린 Task가 남는다)
        sut.clear()
    }

    @Test func handleScenePhase_active시_대기중인_폴링이_재개된다() async throws {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.handleScenePhase(.background)
        sut.resumePolling(scanId: 1, houseId: 1)

        // 백그라운드 상태에서 루프가 파킹됐음을 먼저 관측
        try await waitUntil { sut.isParked }
        #expect(mockRepo.getScanStatusCallCount == 0, "백그라운드에서는 폴링하지 않아야 합니다")

        sut.handleScenePhase(.active)

        try await waitUntil { mockRepo.getScanStatusCallCount > 0 }
        #expect(mockRepo.getScanStatusCallCount > 0, "포그라운드 복귀 후 폴링이 재개되어야 합니다")
        sut.clear()
    }

    @Test func 파킹중_취소하면_폴링없이_Task가_종료된다() async throws {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.handleScenePhase(.background)
        sut.resumePolling(scanId: 1, houseId: 1)
        try await waitUntil { sut.isParked }
        let task = try #require(sut.currentTask)

        sut.cancel()

        // 취소가 파킹을 깨우지 못하면(좀비 Task) 여기서 끝나지 않는다
        await task.value
        #expect(mockRepo.getScanStatusCallCount == 0, "취소된 Task는 폴링 없이 종료되어야 합니다")
    }

    @Test func active가_연속으로_와도_크래시없이_재개된다() async throws {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.handleScenePhase(.background)
        sut.resumePolling(scanId: 1, houseId: 1)
        try await waitUntil { sut.isParked }

        // wake가 멱등하지 않으면(이중 resume) 프로세스가 죽는다
        sut.handleScenePhase(.active)
        sut.handleScenePhase(.active)

        try await waitUntil { mockRepo.getScanStatusCallCount > 0 }
        #expect(mockRepo.getScanStatusCallCount > 0, "복귀 이벤트가 중복돼도 폴링이 재개되어야 합니다")
        sut.clear()
    }

    @Test func 생명주기_전환으로_끊긴_실패는_타임아웃_횟수를_소모하지_않는다() async throws {
        let sut = ScanProcessingManager(
            pollConfig: .init(maxAttempts: 3, interval: .milliseconds(10)),
            artifactStore: store
        )
        sut.configure(scanRepository: mockRepo)
        mockRepo.getScanStatusResult = .failure(.transportError(code: .networkConnectionLost))
        // maxAttempts보다 충분히 많은 횟수만큼 매 실패를 생명주기 전환과 겹치게 만든다.
        // 이후에는 전환을 멈춰 연속 실패로 정상 종료시킨다 (무한 대기 방지)
        mockRepo.onGetScanStatus = { [weak sut] callCount in
            guard let sut, callCount <= 10 else { return }
            sut.handleScenePhase(.inactive)
            sut.handleScenePhase(.active)
        }

        sut.resumePolling(scanId: 1, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed(let failure) = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        // 전환은 실제 대기 시간을 만들지 않으므로 타임아웃 예산을 깎아서는 안 된다
        #expect(failure.userMessage.hasPrefix("상태 조회 실패"), "연속 실패로 끝나야 하는데 실제 실패 메시지: \(failure.userMessage)")
        #expect(mockRepo.cancelScanCallCount == 0, "전환으로 타임아웃에 도달해 서버 스캔이 취소되면 안 됩니다")
        #expect(store.restore() == .polling(scanId: 1, houseId: 1), "기록이 유지되어야 재시도·재시작 복구가 가능합니다")
        mockRepo.onGetScanStatus = nil
    }

    @Test func 폴링_타임아웃시_서버스캔을_파괴하지_않고_재시도할_수_있다() async throws {
        let sut = ScanProcessingManager(
            pollConfig: .init(maxAttempts: 2, interval: .milliseconds(10)),
            artifactStore: store
        )
        sut.configure(scanRepository: mockRepo)
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.resumePolling(scanId: 3, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed(let failure) = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        #expect(failure.userMessage == "처리 시간이 초과되었습니다")
        #expect(mockRepo.cancelScanCallCount == 0, "타임아웃이 서버 스캔을 취소하면 안 됩니다")
        #expect(sut.canRetry, "타임아웃은 재폴링으로 재시도할 수 있어야 합니다")
        #expect(store.restore() == .polling(scanId: 3, houseId: 1), "기록이 유지되어야 재시작 복구가 가능합니다")
    }

    // MARK: - 재시작 복구

    @Test func 업로드미완_기록이_있으면_재시도가능_실패로_복원된다() throws {
        let zipURL = store.zipDestinationURL()
        try Data("zip".utf8).write(to: zipURL)
        store.save(.uploadReady(zipFileName: zipURL.lastPathComponent, houseId: 4))

        // 앱 재시작 시뮬레이션: 같은 스토어로 새 매니저를 구성
        let restored = ScanProcessingManager(
            pollConfig: .init(interval: .milliseconds(50)),
            artifactStore: store
        )
        restored.configure(scanRepository: mockRepo)

        guard case .failed(let failure) = restored.activeScan?.phase else {
            Issue.record("업로드 미완 기록은 재시도 가능한 실패 상태로 복원돼야 합니다")
            return
        }
        #expect(restored.activeScan?.houseId == 4)
        #expect(failure.retrySource == .upload(zipURL: zipURL))
        #expect(restored.canRetry)
        #expect(FileManager.default.fileExists(atPath: zipURL.path), "sweep이 기록된 zip을 지우면 안 됩니다")
    }

    // MARK: - retry (업로드 실패)

    @Test func retry_업로드실패후_재시도하면_업로드가_다시_수행된다() async throws {
        mockRepo.uploadScanResult = .success(ScanResult(scanId: 10, status: "PROCESSING"))
        mockRepo.getScanStatusResult = .success("PROCESSING")
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 0, houseId: 1,
                phase: .failed(.init(
                    userMessage: "업로드 실패",
                    retrySource: .upload(zipURL: URL(fileURLWithPath: "/tmp/retry.zip"))
                ))
            )
        )

        #expect(sut.canRetry)
        sut.retry()

        #expect(sut.activeScan?.phase == .uploading)
        try await waitUntil { sut.activeScan?.phase == .polling }
        #expect(mockRepo.uploadScanCallCount == 1)
        #expect(sut.activeScan?.scanId == 10)
        sut.clear()
    }

    @Test func retry_재시도불가_실패면_거부된다() {
        let failure = ScanProcessingManager.ScanFailure(userMessage: "업로드 실패", retrySource: nil)
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 0, houseId: 1, phase: .failed(failure))
        )

        #expect(!sut.canRetry)
        sut.retry()

        // 거부된 retry는 startStage에 도달하지 않아 Task 자체가 안 생긴다 — sleep 없이 동기적으로 확정
        #expect(sut.currentTask == nil)
        #expect(mockRepo.uploadScanCallCount == 0)
        #expect(sut.activeScan?.phase == .failed(failure))
    }

    @Test func retry_failed_상태가_아니면_거부된다() {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 5, houseId: 1, phase: .polling)
        )

        #expect(!sut.canRetry)
        sut.retry()

        // 거부된 retry는 startStage에 도달하지 않아 Task 자체가 안 생긴다 — sleep 없이 동기적으로 확정
        #expect(sut.currentTask == nil)
        #expect(mockRepo.uploadScanCallCount == 0)
    }

    // MARK: - retry (다운로드 실패)

    @Test func 다운로드실패시_pending이_유지되고_재다운로드를_재시도할_수_있다() async throws {
        mockRepo.getScanStatusResult = .success("COMPLETED")
        mockRepo.getScanPreviewResult = .failure(.transportError(code: .networkConnectionLost))

        sut.resumePolling(scanId: 7, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        // 기록을 유지해야 앱 재시작 시 폴링 재개 → 재다운로드로 복구할 수 있다
        #expect(store.restore() == .polling(scanId: 7, houseId: 1))
        #expect(sut.canRetry)
        let statusCallCountBeforeRetry = mockRepo.getScanStatusCallCount

        sut.retry()

        try await waitUntil { mockRepo.getScanPreviewCallCount == 2 }
        #expect(mockRepo.getScanPreviewCallCount == 2, "재시도 시 프리뷰 재다운로드를 시도해야 합니다")
        #expect(
            mockRepo.getScanStatusCallCount == statusCallCountBeforeRetry,
            "COMPLETED 확인 후의 다운로드 실패 재시도는 재폴링 없이 다운로드만 수행해야 합니다"
        )
    }

    @Test func 잘못된_파일URL이면_재시도_불가로_실패한다() async throws {
        mockRepo.getScanStatusResult = .success("COMPLETED")
        // URL(string: "")은 nil — 서버 데이터 결함 시나리오
        mockRepo.getScanPreviewResult = .success("")

        sut.resumePolling(scanId: 7, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed(let failure) = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        #expect(failure.userMessage == "잘못된 파일 URL")
        #expect(!sut.canRetry, "같은 응답으론 재시도해도 결과가 같으므로 재시도가 노출되면 안 됩니다")
    }

    @Test func 상태조회_연속실패시_pending이_유지되고_재시도할_수_있다() async throws {
        mockRepo.getScanStatusResult = .failure(.transportError(code: .networkConnectionLost))

        sut.resumePolling(scanId: 9, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        // 일시적 네트워크 문제일 수 있으므로 기록을 유지해 재시도·재시작 복구가 가능해야 한다
        #expect(store.restore() == .polling(scanId: 9, houseId: 1))
        #expect(sut.canRetry)

        let callCountBeforeRetry = mockRepo.getScanStatusCallCount
        sut.retry()

        #expect(sut.activeScan?.phase == .polling)
        try await waitUntil { mockRepo.getScanStatusCallCount > callCountBeforeRetry }
        #expect(mockRepo.getScanStatusCallCount > callCountBeforeRetry, "재시도 시 재폴링부터 수행해야 합니다")
        sut.clear()
    }
}
