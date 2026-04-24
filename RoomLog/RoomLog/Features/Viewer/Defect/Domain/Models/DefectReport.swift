//
//  DefectData.swift
//  
//
//  Created by 송민교 on 4/12/26.
//
import Foundation

struct DefectReport {
    let room: DefectRoomData
    let defectCount: Int
    let minRepairCost: Int
    let repairArea: Float
    let defects: [DefectReportDetail]
}
