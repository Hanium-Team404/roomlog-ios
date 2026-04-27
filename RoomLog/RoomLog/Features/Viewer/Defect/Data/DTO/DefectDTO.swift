//
//  DefectDTO.swift
//  
//
//  Created by 송민교 on 4/12/26.
//
import Foundation

// MARK: - Response DTO
struct DefectDataResponseDTO: Codable {
    let mainDefect: DefectSummaryDTO
    let defects: [DefectSummaryDTO]
    let defectsCount: Int
}
 
// TODO: - 추후 수정
struct DefectSummaryDTO: Codable {
    
}
