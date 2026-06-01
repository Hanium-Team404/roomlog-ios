//
//  ScanProcessingManagerTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import XCTest
@testable import RoomLog
internal import SwiftUI

@MainActor
final class ScanProcessingManagerTests: XCTestCase {

    private var mockRepo: MockScanRepository!
    private var sut: ScanProcessingManager!

    override func setUp() {
        super.setUp()
        mockRepo = MockScanRepository()
        sut = ScanProcessingManager()
        sut.configure(scanRepository: mockRepo)
        // 이전 테스트에서 남은 UserDefaults 정리
        UserDefaults.standard.removeObject(forKey: "ScanProcessing_scanId")
        UserDefaults.standard.removeObject(forKey: "ScanProcessing_houseId")
    }

    // MARK: - startProcessing (폴링 재개)

    func test_startProcessing_호출시_polling_상태가_된다() {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.startProcessing(scanId: 100, houseId: 1)

        XCTAssertEqual(sut.activeScan?.scanId, 100)
        XCTAssertEqual(sut.activeScan?.houseId, 1)
        XCTAssertEqual(sut.activeScan?.phase, .polling)
    }

    // MARK: - cancel

    func test_cancel_호출시_activeScan이_nil이_된다() {
        sut.startProcessing(scanId: 100, houseId: 1)

        sut.cancel()

        XCTAssertNil(sut.activeScan)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "ScanProcessing_scanId"), 0)
    }

    // MARK: - clear

    func test_clear_호출시_상태가_초기화된다() {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 1, houseId: 1,
                phase: .completed(fileURL: URL(fileURLWithPath: "/tmp/test.ply"))
            )
        )

        sut.clear()

        XCTAssertNil(sut.activeScan)
    }

    // MARK: - completedScan

    func test_completedScan_완료된_스캔이_있으면_반환한다() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.ply")
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 1, houseId: 5, phase: .completed(fileURL: fileURL))
        )

        let result = sut.completedScan(for: 5)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.scanId, 1)
    }

    func test_completedScan_다른_houseId면_nil을_반환한다() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.ply")
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 1, houseId: 5, phase: .completed(fileURL: fileURL))
        )

        let result = sut.completedScan(for: 99)

        XCTAssertNil(result)
    }

    // MARK: - isProcessing

    func test_isProcessing_polling중이면_true를_반환한다() {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 1, houseId: 3, phase: .polling)
        )

        XCTAssertTrue(sut.isProcessing(for: 3))
    }

    func test_isProcessing_completed면_false를_반환한다() {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 1, houseId: 3,
                phase: .completed(fileURL: URL(fileURLWithPath: "/tmp/test.ply"))
            )
        )

        XCTAssertFalse(sut.isProcessing(for: 3))
    }

    // MARK: - handleScenePhase

    func test_handleScenePhase_background시_폴링이_일시정지된다() {
        sut.handleScenePhase(.background)
        // isInBackground는 private이므로 동작으로 검증
        // 백그라운드에서 startProcessing하면 API 호출 없이 대기
        sut.startProcessing(scanId: 1, houseId: 1)

        // 짧은 대기 후 API가 호출되지 않았는지 확인
        let expectation = expectation(description: "폴링 대기")
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(mockRepo.getScanStatusCallCount, 0)
    }

    func test_handleScenePhase_active시_폴링이_재개된다() {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        // 백그라운드 → 폴링 시작 → 포그라운드 복귀
        sut.handleScenePhase(.background)
        sut.startProcessing(scanId: 1, houseId: 1)
        sut.handleScenePhase(.active)

        let expectation = expectation(description: "폴링 재개 대기")
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)

        XCTAssertGreaterThan(mockRepo.getScanStatusCallCount, 0, "포그라운드 복귀 후 폴링이 재개되어야 합니다")
    }
}
