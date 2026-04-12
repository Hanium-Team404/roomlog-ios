//
//  ScanResultResponseDTO.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation

struct ScanResultResponseDTO: Codable {
    let scanId: Int

    func toDomain() -> ScanResult {
        ScanResult(scanId: scanId)
    }
}
