//
//  ComparisonRepositoryProtocol.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

protocol ComparisonRepositoryProtocol {
    /// 집 목록 조회
    func getHouses() async throws -> [House]
    /// 집의 방 목록 조회
    func getRooms(houseId: Int) async throws -> [ComparisonScan]
    /// 비교 분석 내역 조회
    func getComparisonHistories(houseId: Int) async throws -> [ComparisonHistory]
}
