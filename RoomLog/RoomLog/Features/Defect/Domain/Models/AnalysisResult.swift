//
//  AnalysisResult.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

struct AnalysisResult {
    let analysisId: Int
    let roomId: Int
    let status: String
    let defectCount: Int
    /// 출장비(원). totalCost에 이미 포함되어 있다.
    let visitFee: Int
    let totalCost: Int
    let totalArea: Float
    let defects: [DefectReportDetail]
    let plyURL: String?
    let createdAt: Date?
}
