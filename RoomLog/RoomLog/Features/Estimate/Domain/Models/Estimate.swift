//
//  Estimate.swift
//  RoomLog
//
//  Created by 송민교 on 5/17/26.
//

import Foundation

struct Estimate: Identifiable, Hashable {
    let id: Int
    let status: EstimateStatus
    let message: String?
    let defectType: String
    let defectSeverity: Severity
    let defectLocation: String
    let repairCost: Int
    let providerName: String
    let providerPhone: String?
    let providerAddress: String?
    let createdAt: Date?
}

enum EstimateStatus: Hashable {
    case requested, sent, failed, completed

    init(rawString: String) {
        switch rawString.uppercased() {
        case "REQUESTED": self = .requested
        case "SENT": self = .sent
        case "FAILED": self = .failed
        case "COMPLETED": self = .completed
        default: self = .requested
        }
    }

    var label: String {
        switch self {
        case .requested: "대기중"
        case .sent: "진행중"
        case .failed: "실패"
        case .completed: "완료"
        }
    }
}
