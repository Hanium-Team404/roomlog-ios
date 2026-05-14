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
    let fileURL: String
    let scanType: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case status
        case scanId = "scan_id"
        case fileURL = "file_url"
        case scanType = "scan_type"
        case createdAt = "created_at"
    }

    func toDomain() -> ScanResult {
        ScanResult(
            scanId: scanId,
            status: status,
            fileURL: fileURL,
            scanType: scanType
        )
    }
}
