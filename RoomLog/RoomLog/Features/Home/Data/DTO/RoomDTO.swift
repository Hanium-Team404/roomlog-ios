//
//  RoomDTO.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

// MARK: - Request DTO

struct CreateRoomRequestDTO: Encodable {
    let name: String
    let scanId: Int

    enum CodingKeys: String, CodingKey {
        case name
        case scanId = "scan_id"
    }
}

struct UpdateRoomRequestDTO: Encodable {
    let name: String
    let moveInDate: String
    let moveOutDate: String?

    enum CodingKeys: String, CodingKey {
        case name
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
    }
}

// MARK: - Response DTO

struct RoomSummaryDTO: Codable {
    let roomId: Int
    let name: String
    let fileURL: String?
    let latestScan: LatestScanDTO?
    let recentScanDate: String?
    let latestScanStatus: String?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case fileURL = "thumbnail_url"
        case latestScan = "latest_scan"
        case recentScanDate = "move_in_date"
        case latestScanStatus = "latest_scan_status"
    }

    func toDomain() -> RoomSummary {
        RoomSummary(
            id: roomId,
            name: name,
            thumbnailURL: fileURL,
            latestScan: latestScan?.toDomain(),
            recentScanDate: recentScanDate.flatMap { Date.fromServerDate($0) },
            latestScanStatus: latestScanStatus
        )
    }
}

struct LatestScanDTO: Codable {
    let scanId: Int

    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
    }

    func toDomain() -> LatestScan {
        LatestScan(scanId: scanId)
    }
}

struct CreateRoomResponseDTO: Codable {
    let roomId: Int
    let name: String
    let moveInDate: String?
    let moveOutDate: String?
    let fileURL: String?
    let createdAt: String
    let linkedScan: LinkedScanDTO?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case fileURL = "ply_url"
        case createdAt = "created_at"
        case linkedScan = "linked_scan"
    }
}

struct LinkedScanDTO: Codable {
    let scanId: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
        case status
    }
}

struct RoomDetailResponseDTO: Codable {
    let roomId: Int
    let name: String
    let moveInDate: String?
    let moveOutDate: String?
    let fileURL: String?
    let createdAt: String
    let latestScan: ScanDetailDTO?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case fileURL = "ply_url"
        case createdAt = "created_at"
        case latestScan = "latest_scan"
    }

    func toDomain() throws -> RoomDetail {
        guard let parsedCreatedAt = Date.fromServerDateTime(createdAt) else {
            throw RepositoryError.decodingError(detail: "RoomDetail.createdAt 파싱 실패: \(createdAt)")
        }
        return RoomDetail(
            id: roomId,
            name: name,
            moveInDate: moveInDate.flatMap { Date.fromServerDate($0) },
            moveOutDate: moveOutDate.flatMap { Date.fromServerDate($0) },
            thumbnailURL: fileURL,
            fileURL: fileURL,
            createdAt: parsedCreatedAt,
            latestScan: try latestScan?.toDomain()
        )
    }
}

struct ScanDetailDTO: Codable {
    let scanId: Int
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
        case status
        case createdAt = "created_at"
    }

    func toDomain() throws -> ScanDetail {
        guard let parsedCreatedAt = Date.fromServerDateTime(createdAt) else {
            throw RepositoryError.decodingError(detail: "ScanDetail.createdAt 파싱 실패: \(createdAt)")
        }
        return ScanDetail(
            scanId: scanId,
            status: status,
            createdAt: parsedCreatedAt
        )
    }
}

struct UpdateRoomResponseDTO: Codable {
    let roomId: Int
    let name: String
    let moveInDate: String?
    let moveOutDate: String?
    let fileURL: String?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case fileURL = "ply_url"
    }
}

struct DeleteRoomResponseDTO: Codable {
    let deletedRoomId: Int
    let mainRoomId: Int?

    enum CodingKeys: String, CodingKey {
        case deletedRoomId = "deleted_room_id"
        case mainRoomId = "main_room_id"
    }
}
