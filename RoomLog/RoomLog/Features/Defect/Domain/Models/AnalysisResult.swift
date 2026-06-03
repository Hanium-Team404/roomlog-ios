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
    let totalCost: Int
    let totalArea: Float
    let defects: [DefectReportDetail]
    let plyURL: String?
    let createdAt: Date?
}
