//
//  HouseDTO.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

// MARK: - Request DTO

struct CreateHouseRequestDTO: Encodable {
    let name: String
}

struct UpdateHouseRequestDTO: Encodable {
    let name: String
}

// MARK: - Response DTO

struct CreateHouseResponseDTO: Codable {
    let houseId: Int
    let name: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case houseId = "house_id"
        case name
        case createdAt = "created_at"
    }
}

struct GetHousesResponseDTO: Codable {
    let houses: [HouseSummaryDTO]
    let mainHouse: HouseSummaryDTO?
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case houses
        case mainHouse = "main_house"
        case totalCount = "total_count"
    }
}

struct HouseSummaryDTO: Codable {
    let houseId: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case houseId = "house_id"
        case name
    }

    func toDomain() -> House {
        House(houseId: houseId, name: name)
    }
}

struct UpdateHouseResponseDTO: Codable {
    let houseId: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case houseId = "house_id"
        case name
    }
}

struct DeleteHouseResponseDTO: Codable {
    let deletedHouseId: Int
    let mainHouseId: Int?

    enum CodingKeys: String, CodingKey {
        case deletedHouseId = "deleted_house_id"
        case mainHouseId = "main_house_id"
    }
}

struct SetMainHouseResponseDTO: Codable {
    let mainHouseId: Int

    enum CodingKeys: String, CodingKey {
        case mainHouseId = "main_house_id"
    }
}

struct GetHouseRoomsResponseDTO: Codable {
    let rooms: [RoomSummaryDTO]
    let houseId: Int
    let houseName: String
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case rooms
        case houseId = "house_id"
        case houseName = "house_name"
        case totalCount = "total_count"
    }
}
