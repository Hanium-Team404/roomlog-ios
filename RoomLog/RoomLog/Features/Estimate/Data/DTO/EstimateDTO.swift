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

// MARK: - Estimate List

struct EstimateListResponseDTO: Codable {
    let estimates: [EstimateItemDTO]
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case estimates
        case totalCount = "total_count"
    }
}

struct EstimateItemDTO: Codable {
    let estimateId: Int
    let status: String
    let displayStatus: String
    let message: String?
    let defects: [EstimateDefectDTO]
    let providerName: String
    let providerPhone: String?
    let providerAddress: String?
    let createdAt: String
    let repairId: Int?
    let repairCost: Int?
    let repairedAt: String?

    enum CodingKeys: String, CodingKey {
        case estimateId = "estimate_id"
        case status
        case displayStatus = "display_status"
        case message
        case defects
        case providerName = "provider_name"
        case providerPhone = "provider_phone"
        case providerAddress = "provider_address"
        case createdAt = "created_at"
        case repairId = "repair_id"
        case repairCost = "repair_cost"
        case repairedAt = "repaired_at"
    }

    func toDomain() -> Estimate {
        Estimate(
            id: estimateId,
            status: EstimateStatus(rawString: status),
            displayStatus: EstimateDisplayStatus(rawString: displayStatus),
            message: message,
            defects: defects.map { $0.toDomain() },
            providerName: providerName,
            providerPhone: providerPhone,
            providerAddress: providerAddress,
            createdAt: Self.parseDate(createdAt),
            repairId: repairId,
            repairCost: repairCost,
            repairedAt: repairedAt.flatMap { Self.parseDate($0) }
        )
    }

    static func parseDate(_ string: String) -> Date? {
        guard string.contains(".") else {
            return Date.fromServerDateTime(string)
        }
        // 소수점 이하를 3자리로 잘라 표준 SSS 포맷으로 정규화
        let normalized: String
        if let dotIndex = string.firstIndex(of: ".") {
            let fractionalStart = string.index(after: dotIndex)
            let fractional = string[fractionalStart...]
            let trimmed = String(fractional.prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
            normalized = String(string[..<fractionalStart]) + trimmed
        } else {
            normalized = string
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.date(from: normalized)
    }
}

struct EstimateDefectDTO: Codable {
    let defectId: Int
    let analysisId: Int?
    let type: String
    let location: String
    let severity: String
    let area: Double?
    let estimatedCost: Int?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case defectId = "defect_id"
        case analysisId = "analysis_id"
        case type, location, severity, area, description
        case estimatedCost = "estimated_cost"
    }

    func toDomain() -> EstimateDefect {
        EstimateDefect(
            defectId: defectId,
            analysisId: analysisId,
            type: type,
            location: location,
            severity: Severity(rawString: severity),
            area: area,
            estimatedCost: estimatedCost,
            description: description
        )
    }
}

// MARK: - Estimate Preview

struct EstimatePreviewRequestDTO: Encodable {
    let message: String
    let analysisId: Int
    let providerExternalId: String

    enum CodingKeys: String, CodingKey {
        case message
        case analysisId = "analysis_id"
        case providerExternalId = "provider_external_id"
    }
}

struct EstimatePreviewResponseDTO: Codable {
    let provider: PreviewProviderDTO
    let defects: [PreviewDefectDTO]
    let summary: PreviewSummaryDTO
    let analysisId: Int
    let roomId: Int
    let messagePreview: String

    enum CodingKeys: String, CodingKey {
        case provider, defects, summary
        case analysisId = "analysis_id"
        case roomId = "room_id"
        case messagePreview = "message_preview"
    }

    func toDomain() -> EstimatePreview {
        EstimatePreview(
            providerName: provider.providerName,
            providerPhone: provider.providerPhone,
            providerAddress: provider.providerAddress,
            providerExternalId: provider.providerExternalId,
            defects: defects.map { $0.toDomain() },
            defectCount: summary.defectCount,
            totalCost: summary.totalCost,
            analysisId: analysisId,
            roomId: roomId,
            messagePreview: messagePreview
        )
    }
}

struct PreviewProviderDTO: Codable {
    let providerExternalId: String
    let providerName: String
    let providerPhone: String
    let providerAddress: String

    enum CodingKeys: String, CodingKey {
        case providerExternalId = "provider_external_id"
        case providerName = "provider_name"
        case providerPhone = "provider_phone"
        case providerAddress = "provider_address"
    }
}

struct PreviewDefectDTO: Codable {
    let type: String
    let location: String
    let severity: String
    let defectId: Int
    let estimatedCost: Int

    enum CodingKeys: String, CodingKey {
        case type, location, severity
        case defectId = "defect_id"
        case estimatedCost = "estimated_cost"
    }

    func toDomain() -> EstimatePreviewDefect {
        EstimatePreviewDefect(
            defectId: defectId,
            type: DefectType(rawString: type),
            location: location,
            severity: Severity(rawString: severity),
            estimatedCost: estimatedCost
        )
    }
}

struct PreviewSummaryDTO: Codable {
    let defectCount: Int
    let totalCost: Int

    enum CodingKeys: String, CodingKey {
        case defectCount = "defect_count"
        case totalCost = "total_cost"
    }
}

// MARK: - Estimate Detail

struct EstimateDetailResponseDTO: Codable {
    let status: String
    let message: String?
    let defects: [EstimateDetailDefectDTO]
    let estimateId: Int
    let providerName: String
    let providerPhone: String?
    let providerAddress: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case status, message, defects
        case estimateId = "estimate_id"
        case providerName = "provider_name"
        case providerPhone = "provider_phone"
        case providerAddress = "provider_address"
        case createdAt = "created_at"
    }

    func toDomain() -> EstimateDetail {
        EstimateDetail(
            id: estimateId,
            status: EstimateStatus(rawString: status),
            message: message,
            defectIds: defects.map(\.defectId),
            providerName: providerName,
            providerPhone: providerPhone,
            providerAddress: providerAddress,
            createdAt: EstimateItemDTO.parseDate(createdAt)
        )
    }
}

struct EstimateDetailDefectDTO: Codable {
    let defectId: Int

    enum CodingKeys: String, CodingKey {
        case defectId = "defect_id"
    }
}

// MARK: - Complete Repair

struct CompleteRepairResponseDTO: Codable {
    let status: String
    let repairId: Int
    let estimateId: Int

    enum CodingKeys: String, CodingKey {
        case status
        case repairId = "repair_id"
        case estimateId = "estimate_id"
    }
}

struct CompleteRepairRequestDTO: Encodable {
    let repairCost: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case repairCost = "repair_cost"
        case note
    }
}

// MARK: - Create Estimate

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
