//
//  ScanResultResponseDTO.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation

struct ScanResultResponseDTO: Codable {
    let status: String
    let scanId: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case scanId = "scan_id"
        case createdAt = "created_at"
    }

    func toDomain() -> ScanResult {
        ScanResult(
            scanId: scanId,
            status: status
        )
    }
}
