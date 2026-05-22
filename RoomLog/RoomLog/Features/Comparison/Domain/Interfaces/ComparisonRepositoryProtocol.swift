//
//  ComparisonRepositoryProtocol.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

protocol ComparisonRepositoryProtocol {
    /// 방 스캔 목록 조회
    func getScans() async throws -> [ComparisonScan]
}
