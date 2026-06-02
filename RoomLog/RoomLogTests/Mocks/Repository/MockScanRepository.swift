//
//  MockScanRepository.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
@testable import RoomLog

final class MockScanRepository: ScanRepositoryProtocol {

    // MARK: - Call Tracking

    var uploadScanCallCount = 0
    var getScanStatusCallCount = 0
    var getScanPreviewCallCount = 0
    var cancelScanCallCount = 0

    // MARK: - Stub Results

    var uploadScanResult: Result<ScanResult, Error> = .success(ScanResult(scanId: 1, status: "COMPLETED"))
    var getScanStatusResult: Result<String, Error> = .success("COMPLETED")
    var getScanPreviewResult: Result<String, Error> = .success("https://example.com/preview.ply")
    var cancelScanResult: Result<Void, Error> = .success(())

    // MARK: - ScanRepositoryProtocol

    func uploadScan(houseId: Int, fileURL: URL) async throws -> ScanResult {
        uploadScanCallCount += 1
        return try uploadScanResult.get()
    }

    func getScanStatus(scanId: Int) async throws -> String {
        getScanStatusCallCount += 1
        return try getScanStatusResult.get()
    }

    func getScanPreview(scanId: Int) async throws -> String {
        getScanPreviewCallCount += 1
        return try getScanPreviewResult.get()
    }

    func cancelScan(scanId: Int) async throws {
        cancelScanCallCount += 1
        try cancelScanResult.get()
    }
}
