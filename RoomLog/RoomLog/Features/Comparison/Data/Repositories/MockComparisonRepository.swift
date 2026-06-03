//
//  MockComparisonRepository.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

final class MockComparisonRepository: ComparisonRepositoryProtocol {
    func getHouses() async throws -> [House] {
        [
            House(houseId: 1, name: "망고의 집", address: "서울시 중구"),
            House(houseId: 2, name: "민교의 집", address: "서울시 강남구")
        ]
    }

    func getRooms(houseId: Int) async throws -> [ComparisonScan] {
        [
            ComparisonScan(id: 1, roomName: "거실", scanDate: Date(timeIntervalSinceNow: -86400 * 90), thumbnailURL: nil),
            ComparisonScan(id: 2, roomName: "안방", scanDate: Date(timeIntervalSinceNow: -86400 * 60), thumbnailURL: nil),
            ComparisonScan(id: 3, roomName: "주방", scanDate: Date(timeIntervalSinceNow: -86400 * 45), thumbnailURL: nil)
        ]
    }
}
