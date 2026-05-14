//
//  EstimateDTO.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

// MARK: - Repair Shop

struct RepairShopListResponseDTO: Codable {
    let type: String?
    let radius: String?
    let sort: String?
    let analysisId: Int?
    let roomId: Int?
    let repairShops: [RepairShopDTO]
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case type, radius, sort
        case analysisId = "analysis_id"
        case roomId = "room_id"
        case repairShops = "repair_shops"
        case totalCount = "total_count"
    }
}

struct RepairShopDTO: Codable {
    let distance: Double
    let providerExternalId: String
    let providerName: String
    let providerPhone: String
    let providerAddress: String
    let providerLat: Double
    let providerLng: Double
    let providerImageURL: String?

    enum CodingKeys: String, CodingKey {
        case distance
        case providerExternalId = "provider_external_id"
        case providerName = "provider_name"
        case providerPhone = "provider_phone"
        case providerAddress = "provider_address"
        case providerLat = "provider_lat"
        case providerLng = "provider_lng"
        case providerImageURL = "provider_image_url"
    }

    func toDomain() -> RepairShop {
        RepairShop(
            externalId: providerExternalId,
            name: providerName,
            phone: providerPhone,
            address: providerAddress,
            latitude: providerLat,
            longitude: providerLng,
            imageURL: providerImageURL,
            distance: distance
        )
    }
}

// MARK: - Estimate

struct CreateEstimateRequestDTO: Encodable {
    let message: String
    let roomId: Int
    let analysisId: Int?
    let defectIds: [Int]
    let providerName: String
    let providerPhone: String
    let providerAddress: String

    enum CodingKeys: String, CodingKey {
        case message
        case roomId = "room_id"
        case analysisId = "analysis_id"
        case defectIds = "defect_ids"
        case providerName = "provider_name"
        case providerPhone = "provider_phone"
        case providerAddress = "provider_address"
    }
}
