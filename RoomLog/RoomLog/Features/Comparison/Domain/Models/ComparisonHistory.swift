//
//  ComparisonHistory.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

struct ComparisonHistory: Identifiable, Hashable {
    let id: Int // analysisId
    let status: AnalysisStatus
    let moveInRoomName: String
    let moveOutRoomName: String
    let defectCount: Int
    let totalCost: Int
    let createdAt: Date?
    let moveInRoomId: Int
    let moveOutRoomId: Int

    var isCompleted: Bool { status == .completed }
}

enum AnalysisStatus: Hashable {
    case pending, completed, failed

    init(rawString: String) {
        switch rawString.uppercased() {
        case "COMPLETED": self = .completed
        case "FAILED": self = .failed
        default: self = .pending
        }
    }

    var label: String {
        switch self {
        case .pending: "분석 중"
        case .completed: "완료"
        case .failed: "실패"
        }
    }
}
