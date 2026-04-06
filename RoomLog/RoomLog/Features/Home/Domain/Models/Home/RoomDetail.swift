//
//  RoomDetail.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

// MARK: - Room Detail Info Model

struct RoomDetail: Codable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let moveInDate: String
    let moveOutDate: String
    let fileURL: String?
    let createdAt: String
    let latestScan: ScanDetail?
}

struct ScanDetail: Codable {
    let scanId: Int
    let status: String
    let createdAt: String
}
