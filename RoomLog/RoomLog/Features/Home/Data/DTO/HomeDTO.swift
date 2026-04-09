//
//  HomeDTO.swift
//  RoomLog
//
//  Created by 김도연 on 4/9/26.
//

import Foundation

// MARK: - Response DTO

struct HomeDataResponseDTO: Codable {
    let mainRoom: RoomSummaryDTO
    let rooms: [RoomSummaryDTO]
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case mainRoom = "main_room"
        case rooms
        case totalCount = "total_count"
    }
}

struct RoomSummaryDTO: Codable {
    let roomId: Int
    let name: String
    let address: String
    let thumbnailURL: String?
    let latestScan: LatestScanDTO?
    let moveInDate: String?
    let moveOutDate: String?
    let recentScanDate: String?
    let latestScanStatus: String?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case address
        case thumbnailURL = "thumbnail_url"
        case latestScan = "latest_scan"
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case recentScanDate = "recent_scan_date"
        case latestScanStatus = "latest_scan_status"
    }

    func toDomain() -> RoomSummary {
        RoomSummary(
            id: roomId,
            name: name,
            address: address,
            thumbnailURL: thumbnailURL,
            latestScan: latestScan.map { LatestScan(scanId: $0.scanId, scanType: $0.scanType) },
            moveInDate: moveInDate.flatMap { Date.fromServerDate($0) },
            moveOutDate: moveOutDate.flatMap { Date.fromServerDate($0) },
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
}

struct RoomDetailResponseDTO: Codable {
    let roomId: Int
    let name: String
    let address: String
    let moveInDate: String
    let moveOutDate: String
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

    func toDomain() -> RoomDetail {
        RoomDetail(
            id: roomId,
            name: name,
            address: address,
            moveInDate: Date.fromServerDate(moveInDate) ?? Date(),
            moveOutDate: Date.fromServerDate(moveOutDate) ?? Date(),
            fileURL: fileURL,
            createdAt: Date.fromServerDateTime(createdAt) ?? Date(),
            latestScan: latestScan?.toDomain()
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

    func toDomain() -> ScanDetail {
        ScanDetail(
            scanId: scanId,
            status: status,
            createdAt: Date.fromServerDateTime(createdAt) ?? Date()
        )
    }
}

struct UpdatedRoomDetailResponseDTO: Codable {
    let roomId: Int
    let name: String
    let address: String
    let moveInDate: String
    let moveOutDate: String
    let thumbnailURL: String?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case name
        case address
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
        case thumbnailURL = "thumbnail_url"
    }

    func toDomain() -> UpdatedRoomDetail {
        UpdatedRoomDetail(
            roomId: roomId,
            name: name,
            address: address,
            moveInDate: Date.fromServerDate(moveInDate) ?? Date(),
            moveOutDate: Date.fromServerDate(moveOutDate) ?? Date(),
            thumbnailURL: thumbnailURL
        )
    }
}

// MARK: - Request DTO

struct PatchRoomRequestDTO: Encodable {
    let name: String
    let address: String
    let moveInDate: String
    let moveOutDate: String

    enum CodingKeys: String, CodingKey {
        case name
        case address
        case moveInDate = "move_in_date"
        case moveOutDate = "move_out_date"
    }
}
