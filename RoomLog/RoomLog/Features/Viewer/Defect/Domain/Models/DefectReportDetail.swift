//
//  DefectReportDetail.swift
//  
//
//  Created by 송민교 on 4/12/26.
//
import Foundation

struct DefectReportDetail {
    let id: String
    let defectThumbnailURL: URL
    let type: String
    let severity: Severity
    let description: String
    let repairCost: Int
    let defectArea: Double
    let location: String
    let discoveredDate: Date
    let memo: String?
}

enum Severity {
    case high, medium, low
}
