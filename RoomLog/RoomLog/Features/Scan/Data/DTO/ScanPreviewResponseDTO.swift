//
//  ScanPreviewResponseDTO.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

struct ScanPreviewResponseDTO: Codable {
    let scanId: Int
    let roomId: Int
    let fileURL: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
        case roomId = "room_id"
        case fileURL = "file_url"
        case createdAt = "created_at"
    }
}
