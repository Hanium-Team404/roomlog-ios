//
//  MockComparisonRepository.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

final class MockComparisonRepository: ComparisonRepositoryProtocol {
    func getScans() async throws -> [ComparisonScan] {
        [
            ComparisonScan(id: 1, roomName: "망고의 방", scanDate: Date(timeIntervalSinceNow: -86400 * 90), thumbnailURL: nil, scanType: .moveIn),
            ComparisonScan(id: 2, roomName: "민교의 방", scanDate: Date(timeIntervalSinceNow: -86400 * 60), thumbnailURL: nil, scanType: .moveIn),
            ComparisonScan(id: 3, roomName: "밍교의 방", scanDate: Date(timeIntervalSinceNow: -86400 * 45), thumbnailURL: nil, scanType: .moveIn),
            ComparisonScan(id: 4, roomName: "망고의 방", scanDate: Date(timeIntervalSinceNow: -86400 * 3), thumbnailURL: nil, scanType: .moveOut),
            ComparisonScan(id: 5, roomName: "민교의 방", scanDate: Date(timeIntervalSinceNow: -86400 * 1), thumbnailURL: nil, scanType: .moveOut),
            ComparisonScan(id: 6, roomName: "밍교의 방", scanDate: Date(timeIntervalSinceNow: -86400 * 7), thumbnailURL: nil, scanType: .moveOut),
        ]
    }
}
