//
//  ScanRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation

protocol ScanRepositoryProtocol {
    func uploadScan(roomId: Int, zipFileURL: URL) async throws -> ScanResult
}
