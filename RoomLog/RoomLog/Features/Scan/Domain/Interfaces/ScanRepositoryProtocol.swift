//
//  ScanRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation

/// 도메인 경계 위로는 `RepositoryError`만 올라가도록 typed throws로 강제한다
protocol ScanRepositoryProtocol {
    func uploadScan(houseId: Int, fileURL: URL) async throws(RepositoryError) -> ScanResult
    func getScanStatus(scanId: Int) async throws(RepositoryError) -> String
    func getScanPreview(scanId: Int) async throws(RepositoryError) -> String
    func cancelScan(scanId: Int) async throws(RepositoryError)
}
