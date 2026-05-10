//
//  DefectReportDetail.swift
//  
//
//  Created by 송민교 on 4/12/26.
//
import Foundation

struct DefectReportDetail: Hashable {
    let id: String
    let imageURL: String?
    let type: String
    let severity: Severity
    let description: String
    let repairCost: Int
    let defectArea: Double
    let location: String
    let discoveredDate: Date?
    let memo: String?
    let x: Float?
    let y: Float?
    let z: Float?
}

enum Severity: Hashable {
    case high, medium, low

    init(rawString: String) {
        switch rawString.uppercased() {
        case "HIGH": self = .high
        case "MEDIUM": self = .medium
        default: self = .low
        }
    }
}
