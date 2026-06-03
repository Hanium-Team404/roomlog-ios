//
//  DefectDTO.swift
//
//
//  Created by 송민교 on 4/12/26.
//
import Foundation

struct DefectRoomListResponseDTO: Codable {
    let rooms: [DefectRoomSummaryDTO]
}

struct DefectRoomSummaryDTO: Codable {
    let roomId: Int
    let name: String
    let thumbnailURL: String?
    let recentScanDate: String?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case thumbnailURL = "thumbnail_url"
        case recentScanDate = "recent_scan_date"
    }
}

struct DefectReportResponseDTO: Codable {
    let name: String
    let defects: [DefectDetailDTO]
    let fileURL: String?
    let moveInDate: String?
    let moveOutDate: String?
    let defectCount: Int

    enum CodingKeys: String, CodingKey {
        case name, defects
        case fileURL = "ply_url"
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case defectCount = "defect_count"
    }

    func toDomain(roomId: Int) -> DefectReport {
        let roomData = DefectRoomData(
            id: roomId,
            title: name,
            date: moveInDate.flatMap { Date.fromServerDate($0) } ?? Date(),
            thumbnailURL: fileURL
        )
        let details = defects.map { $0.toDomain() }
        let totalCost = details.reduce(0) { $0 + $1.repairCost }
        let totalArea = details.reduce(0.0) { $0 + $1.defectArea }
        return DefectReport(
            room: roomData,
            imageURL: fileURL,
            defectCount: defectCount,
            minRepairCost: totalCost,
            repairArea: Float(totalArea),
            defects: details
        )
    }
}

// MARK: - Analysis DTO

struct CreateAnalysisResponseDTO: Codable {
    let status: String
    let analysisId: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case analysisId = "analysis_id"
        case createdAt = "created_at"
    }
}

struct AnalysisStatusResponseDTO: Codable {
    let status: String
    let analysisId: Int

    enum CodingKeys: String, CodingKey {
        case status
        case analysisId = "analysis_id"
    }
}

// MARK: - Defect Detail DTO

struct DefectDetailDTO: Codable {
    let type: String
    let location: String
    let area: Double
    let severity: String
    let description: String
    let defectId: Int
    let analysisId: Int
    let estimatedCost: Int
    let imageURL: String?
    let region3d: [Region3dDTO]?

    enum CodingKeys: String, CodingKey {
        case type, location, area, severity, description
        case defectId = "defect_id"
        case analysisId = "analysis_id"
        case estimatedCost = "estimated_cost"
        case imageURL = "image_url"
        case region3d = "region_3d"
    }

    func toDomain() -> DefectReportDetail {
        let firstPoint = region3d?.first
        let points = region3d?.map { DefectPoint3D(x: $0.x, y: $0.y, z: $0.z) } ?? []
        return DefectReportDetail(
            id: defectId,
            imageURL: imageURL,
            type: DefectType(rawString: type),
            severity: Severity(rawString: severity),
            description: description,
            repairCost: estimatedCost,
            defectArea: area,
            location: location,
            discoveredDate: nil,
            memo: nil,
            x: firstPoint?.x,
            y: firstPoint?.y,
            z: firstPoint?.z,
            region3d: points
        )
    }
}

struct Region3dDTO: Codable {
    let x: Float
    let y: Float
    let z: Float
}

// MARK: - Analysis Result DTO

struct AnalysisResultResponseDTO: Codable {
    let status: String
    let summary: AnalysisSummaryDTO
    let defects: [DefectDetailDTO]
    let analysisId: Int
    let roomId: Int
    let plyURL: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case status, summary, defects
        case analysisId = "analysis_id"
        case roomId = "room_id"
        case plyURL = "ply_url"
        case createdAt = "created_at"
    }

    func toDomain() -> AnalysisResult {
        let domainDefects = defects.map { $0.toDomain() }
        let totalArea = domainDefects.reduce(0) { $0 + Float($1.defectArea) }
        return AnalysisResult(
            analysisId: analysisId,
            roomId: roomId,
            status: status,
            defectCount: summary.defectCount,
            totalCost: summary.totalCost,
            totalArea: totalArea,
            defects: domainDefects,
            plyURL: plyURL,
            createdAt: createdAt.flatMap { Date.fromServerDateTime($0) }
        )
    }
}

struct AnalysisSummaryDTO: Codable {
    let defectCount: Int
    let totalCost: Int

    enum CodingKeys: String, CodingKey {
        case defectCount = "defect_count"
        case totalCost = "total_cost"
    }
}
