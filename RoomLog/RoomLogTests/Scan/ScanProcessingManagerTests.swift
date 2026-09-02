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
    /// 테스트마다 고유한 suite를 사용해 호스트 앱 UserDefaults 오염과 병렬 실행 간 간섭을 차단
    private let suiteName: String
    private let defaults: UserDefaults
    private let sut: ScanProcessingManager

    init() throws {
        suiteName = "ScanProcessingManagerTests-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        mockRepo = MockScanRepository()
        sut = ScanProcessingManager(
            pollConfig: .init(interval: .milliseconds(50)),
            userDefaults: defaults
        )
        sut.configure(scanRepository: mockRepo)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
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

    // MARK: - startProcessing (폴링 재개)

    @Test func startProcessing_호출시_polling_상태가_된다() {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.startProcessing(scanId: 100, houseId: 1)

        #expect(sut.activeScan?.scanId == 100)
        #expect(sut.activeScan?.houseId == 1)
        #expect(sut.activeScan?.phase == .polling)
    }

    // MARK: - cancel

    @Test func cancel_호출시_activeScan이_nil이_된다() {
        sut.startProcessing(scanId: 100, houseId: 1)

        sut.cancel()

        #expect(sut.activeScan == nil)
        #expect(defaults.integer(forKey: "ScanProcessing_scanId") == 0)
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
        sut.startProcessing(scanId: 1, houseId: 1)

        try await Task.sleep(for: .milliseconds(300))

        #expect(mockRepo.getScanStatusCallCount == 0)
        // 파킹된 폴링 루프를 깨워서 정리 (안 하면 continuation에 매달린 Task가 남는다)
        sut.clear()
    }

    @Test func handleScenePhase_active시_대기중인_폴링이_재개된다() async throws {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.handleScenePhase(.background)
        sut.startProcessing(scanId: 1, houseId: 1)

        // 백그라운드 상태에서 폴링이 나가지 않음을 먼저 관측 (폴링 간격 50ms의 수 배를 대기)
        try await Task.sleep(for: .milliseconds(300))
        #expect(mockRepo.getScanStatusCallCount == 0, "백그라운드에서는 폴링하지 않아야 합니다")

        sut.handleScenePhase(.active)

        try await waitUntil { mockRepo.getScanStatusCallCount > 0 }
        #expect(mockRepo.getScanStatusCallCount > 0, "포그라운드 복귀 후 폴링이 재개되어야 합니다")
        sut.clear()
    }

    // MARK: - retry (업로드 실패)

    @Test func retry_업로드실패후_재시도하면_업로드가_다시_수행된다() async throws {
        mockRepo.uploadScanResult = .success(ScanResult(scanId: 10, status: "PROCESSING"))
        mockRepo.getScanStatusResult = .success("PROCESSING")
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 0, houseId: 1, phase: .failed("업로드 실패"))
        )
        sut.setPendingRetry(houseId: 1, source: .upload(zipURL: URL(fileURLWithPath: "/tmp/retry.zip")))

        #expect(sut.canRetry)
        sut.retry()

        #expect(sut.activeScan?.phase == .uploading)
        try await waitUntil { sut.activeScan?.phase == .polling }
        #expect(mockRepo.uploadScanCallCount == 1)
        #expect(sut.activeScan?.scanId == 10)
        sut.clear()
    }

    @Test func retry_houseId가_불일치하면_거부된다() async throws {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 0, houseId: 1, phase: .failed("업로드 실패"))
        )
        sut.setPendingRetry(houseId: 2, source: .upload(zipURL: URL(fileURLWithPath: "/tmp/retry.zip")))

        #expect(!sut.canRetry)
        sut.retry()

        try await Task.sleep(for: .milliseconds(100))
        #expect(mockRepo.uploadScanCallCount == 0)
        #expect(sut.activeScan?.phase == .failed("업로드 실패"))
    }

    @Test func retry_failed_상태가_아니면_거부된다() async throws {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 5, houseId: 1, phase: .polling)
        )
        sut.setPendingRetry(houseId: 1, source: .upload(zipURL: URL(fileURLWithPath: "/tmp/retry.zip")))

        #expect(!sut.canRetry)
        sut.retry()

        try await Task.sleep(for: .milliseconds(100))
        #expect(mockRepo.uploadScanCallCount == 0)
    }

    // MARK: - retry (다운로드 실패)

    @Test func 다운로드실패시_pending이_유지되고_재다운로드를_재시도할_수_있다() async throws {
        mockRepo.getScanStatusResult = .success("COMPLETED")
        mockRepo.getScanPreviewResult = .failure(NSError(domain: "test", code: -1))

        sut.startProcessing(scanId: 7, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        // pending을 유지해야 앱 재시작 시 폴링 재개 → 재다운로드로 복구할 수 있다
        #expect(defaults.integer(forKey: "ScanProcessing_scanId") == 7)
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

    @Test func 상태조회_연속실패시_pending이_유지되고_재시도할_수_있다() async throws {
        mockRepo.getScanStatusResult = .failure(NSError(domain: "test", code: -1))

        sut.startProcessing(scanId: 9, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        // 일시적 네트워크 문제일 수 있으므로 pending을 유지해 재시도·재시작 복구가 가능해야 한다
        #expect(defaults.integer(forKey: "ScanProcessing_scanId") == 9)
        #expect(sut.canRetry)

        let callCountBeforeRetry = mockRepo.getScanStatusCallCount
        sut.retry()

        #expect(sut.activeScan?.phase == .polling)
        try await waitUntil { mockRepo.getScanStatusCallCount > callCountBeforeRetry }
        #expect(mockRepo.getScanStatusCallCount > callCountBeforeRetry, "재시도 시 재폴링부터 수행해야 합니다")
        sut.clear()
    }
}
