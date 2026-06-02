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
    let displayStatus: EstimateDisplayStatus
    let message: String?
    let defects: [EstimateDefect]
    let providerName: String
    let providerPhone: String?
    let providerAddress: String?
    let createdAt: Date?
    let repairId: Int?
    let repairCost: Int?
    let repairedAt: Date?
}

struct EstimateDefect: Identifiable, Hashable {
    let defectId: Int
    let analysisId: Int?
    let type: String
    let location: String
    let severity: Severity
    let area: Double?
    let estimatedCost: Int?
    let description: String?

    var id: Int { defectId }

    var localizedType: String {
        switch type.uppercased() {
        case "CRACK": return "균열"
        case "MOLD": return "곰팡이"
        case "LEAK": return "누수"
        case "PEELING": return "박리"
        case "STAIN": return "얼룩"
        case "DAMAGE": return "파손"
        default: return type
        }
    }
}

// MARK: - Estimate Preview

struct EstimatePreview {
    let providerName: String
    let providerPhone: String
    let providerAddress: String
    let providerExternalId: String
    let defects: [EstimatePreviewDefect]
    let defectCount: Int
    let totalCost: Int
    let analysisId: Int
    let roomId: Int
    let messagePreview: String
}

struct EstimatePreviewDefect: Identifiable, Hashable {
    let defectId: Int
    let type: DefectType
    let location: String
    let severity: Severity
    let estimatedCost: Int

    var id: Int { defectId }
}

// MARK: - Estimate Detail

struct EstimateDetail {
    let id: Int
    let status: EstimateStatus
    let message: String?
    let defectIds: [Int]
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
        case .sent: "발송됨"
        case .failed: "실패"
        case .completed: "완료"
        }
    }
}

enum EstimateDisplayStatus: Hashable {
    case inProgress, completed

    init(rawString: String) {
        switch rawString.uppercased() {
        case "COMPLETED": self = .completed
        default: self = .inProgress
        }
    }

    var label: String {
        switch self {
        case .inProgress: "진행중"
        case .completed: "완료"
        }
    }
}
