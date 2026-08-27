//
//  SelfRepairDTO.swift
//  RoomLog
//
//  Created by wk1717 on 8/26/26.
//

import Foundation

struct SelfRepairResponseDTO: Codable {
    let description: String
    let videos: [SelfRepairVideoDTO]
    let items: [SelfRepairItemDTO]
    let defectId: Int
    let selfRepairPossible: Bool
    let totalCost: Int

    enum CodingKeys: String, CodingKey {
        case description, videos, items
        case defectId = "defect_id"
        case selfRepairPossible = "self_repair_possible"
        case totalCost = "total_cost"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        videos = try container.decodeIfPresent([SelfRepairVideoDTO].self, forKey: .videos) ?? []
        items = try container.decodeIfPresent([SelfRepairItemDTO].self, forKey: .items) ?? []
        defectId = try container.decodeIfPresent(Int.self, forKey: .defectId) ?? 0
        selfRepairPossible = try container.decodeIfPresent(Bool.self, forKey: .selfRepairPossible) ?? false
        totalCost = try container.decodeIfPresent(Int.self, forKey: .totalCost) ?? 0
    }

    func toDomain() -> SelfRepairGuide {
        SelfRepairGuide(
            defectId: defectId,
            isPossible: selfRepairPossible,
            description: description,
            videos: videos.map { $0.toDomain() },
            items: items.map { $0.toDomain() },
            totalCost: totalCost
        )
    }
}

struct SelfRepairVideoDTO: Codable {
    let title: String
    let url: String
    let channel: String
    let thumbnailURL: String?

    enum CodingKeys: String, CodingKey {
        case title, url, channel
        case thumbnailURL = "thumbnail_url"
    }

    func toDomain() -> SelfRepairVideo {
        SelfRepairVideo(
            title: title,
            urlString: url,
            channel: channel,
            thumbnailURLString: thumbnailURL
        )
    }
}

struct SelfRepairItemDTO: Codable {
    let name: String
    let price: Int
    let url: String
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case name, price, url
        case imageURL = "image_url"
    }

    func toDomain() -> SelfRepairItem {
        SelfRepairItem(
            name: name,
            price: price,
            urlString: url,
            imageURLString: imageURL
        )
    }
}
