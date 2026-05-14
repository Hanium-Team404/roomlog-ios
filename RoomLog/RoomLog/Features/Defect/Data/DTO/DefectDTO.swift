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
    let address: String
    let defects: [DefectDetailDTO]
    let roomId: Int
    let thumbnailUrl: String?
    let moveInDate: String?
    let moveOutDate: String?
    let defectCount: Int

    enum CodingKeys: String, CodingKey {
        case name, address, defects
        case roomId = "room_id"
        case thumbnailUrl = "thumbnail_url"
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case defectCount = "defect_count"
    }

    func toDomain() -> DefectReport {
        let roomData = DefectRoomData(
            id: roomId,
            title: name,
            date: moveInDate.flatMap { Date.fromServerDate($0) } ?? Date(),
            thumbnailURL: thumbnailUrl
        )
        let details = defects.map { $0.toDomain() }
        let totalCost = details.reduce(0) { $0 + $1.repairCost }
        let totalArea = details.reduce(0.0) { $0 + $1.defectArea }
        return DefectReport(
            room: roomData,
            imageURL: thumbnailUrl,
            defectCount: defectCount,
            minRepairCost: totalCost,
            repairArea: Float(totalArea),
            defects: details
        )
    }
}

struct DefectDetailDTO: Codable {
    let type: String
    let location: String
    let area: Double
    let severity: String
    let x: Float?
    let y: Float?
    let z: Float?
    let description: String
    let defectId: Int
    let estimatedCost: Int
    let beforeImageUrl: String?
    let afterImageUrl: String?
    let inspectionImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case type, location, area, severity, x, y, z, description
        case defectId = "defect_id"
        case estimatedCost = "estimated_cost"
        case beforeImageUrl = "before_image_url"
        case afterImageUrl = "after_image_url"
        case inspectionImageUrl = "inspection_image_url"
    }

    func toDomain() -> DefectReportDetail {
        DefectReportDetail(
            id: defectId,
            imageURL: inspectionImageUrl ?? beforeImageUrl,
            type: type,
            severity: Severity(rawString: severity),
            description: description,
            repairCost: estimatedCost,
            defectArea: area,
            location: location,
            discoveredDate: nil,
            memo: nil,
            x: x,
            y: y,
            z: z
        )
    }
}
