//
//  ComparisonHistory.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

struct ComparisonHistory: Identifiable, Hashable {
    let id: Int // analysisId
    let moveInRoomName: String
    let moveOutRoomName: String
    let defectCount: Int
    let totalCost: Int
    let createdAt: Date?
    let moveInRoomId: Int
    let moveOutRoomId: Int
}
