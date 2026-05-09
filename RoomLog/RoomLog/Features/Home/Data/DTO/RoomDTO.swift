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
    let address: String
    let moveInDate: String
    let moveOutDate: String?

    enum CodingKeys: String, CodingKey {
        case name
        case address
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
    }
}

// MARK: - Response DTO

struct RoomSummaryDTO: Codable {
    let roomId: Int
    let name: String
    let thumbnailURL: String?
    let latestScan: LatestScanDTO?
    let recentScanDate: String?
    let latestScanStatus: String?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case thumbnailURL = "thumbnail_url"
        case latestScan = "latest_scan"
        case recentScanDate = "recent_scan_date"
        case latestScanStatus = "latest_scan_status"
    }

    func toDomain() -> RoomSummary {
        RoomSummary(
            id: roomId,
            name: name,
            thumbnailURL: thumbnailURL,
            latestScan: latestScan?.toDomain(),
            recentScanDate: recentScanDate.flatMap { Date.fromServerDateTime($0) },
            latestScanStatus: latestScanStatus
        )
    }
}

struct LatestScanDTO: Codable {
    let scanId: Int
    let scanType: String

    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
        case scanType = "scan_type"
    }

    func toDomain() -> LatestScan {
        LatestScan(scanId: scanId, scanType: scanType)
    }
}

struct CreateRoomResponseDTO: Codable {
    let roomId: Int
    let name: String
    let address: String?
    let moveInDate: String?
    let moveOutDate: String?
    let thumbnailURL: String?
    let createdAt: String
    let linkedScan: LinkedScanDTO?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case address
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case thumbnailURL = "thumbnail_url"
        case createdAt = "created_at"
        case linkedScan = "linked_scan"
    }
}

struct LinkedScanDTO: Codable {
    let scanId: Int
    let status: String
    let scanType: String

    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
        case status
        case scanType = "scan_type"
    }
}

struct RoomDetailResponseDTO: Codable {
    let roomId: Int
    let name: String
    let address: String?
    let moveInDate: String?
    let moveOutDate: String?
    let thumbnailURL: String?
    let fileURL: String?
    let createdAt: String
    let latestScan: ScanDetailDTO?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case address
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case thumbnailURL = "thumbnail_url"
        case fileURL = "file_url"
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
            address: address,
            moveInDate: moveInDate.flatMap { Date.fromServerDate($0) },
            moveOutDate: moveOutDate.flatMap { Date.fromServerDate($0) },
            thumbnailURL: thumbnailURL,
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
    let address: String?
    let moveInDate: String?
    let moveOutDate: String?
    let thumbnailURL: String?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case address
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case thumbnailURL = "thumbnail_url"
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
