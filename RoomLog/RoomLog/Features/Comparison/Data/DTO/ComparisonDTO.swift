//
//  ComparisonDTO.swift
//  RoomLog
//
//  Created by minkyo on 6/4/26.
//

import Foundation

struct ComparisonHistoryDTO: Codable {
    let status: String
    let summary: ComparisonSummaryDTO
    let analysisID: Int
    let createdAt: String?
    let inRoom: ComparisonRoomDTO
    let outRoom: ComparisonRoomDTO

    enum CodingKeys: String, CodingKey {
        case status, summary
        case analysisID = "analysis_id"
        case createdAt = "created_at"
        case inRoom = "in_room"
        case outRoom = "out_room"
    }

    func toDomain() -> ComparisonHistory {
        ComparisonHistory(
            id: analysisID,
            status: AnalysisStatus(rawString: status),
            moveInRoomName: inRoom.name,
            moveOutRoomName: outRoom.name,
            defectCount: summary.defectCount,
            totalCost: summary.totalCost,
            createdAt: createdAt.flatMap { Date.fromServerDateTime($0) },
            moveInRoomId: inRoom.roomID,
            moveOutRoomId: outRoom.roomID
        )
    }
}

struct ComparisonSummaryDTO: Codable {
    let defectCount: Int
    let totalCost: Int

    enum CodingKeys: String, CodingKey {
        case defectCount = "defect_count"
        case totalCost = "total_cost"
    }
}

struct ComparisonRoomDTO: Codable {
    let name: String
    let roomID: Int
    let thumbnailURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case roomID = "room_id"
        case thumbnailURL = "thumbnail_url"
    }
}
