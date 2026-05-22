//
//  ScanRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation

protocol ScanRepositoryProtocol {
    func uploadScan(houseId: Int, fileURL: URL) async throws -> ScanResult
    func getScanStatus(scanId: Int) async throws -> String
    func getScanPreview(scanId: Int) async throws -> String
    func cancelScan(scanId: Int) async throws
}
