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
    let moveInDate: Date
    let moveOutDate: Date
    let fileURL: String?
    let createdAt: Date
    let latestScan: ScanDetail?
}

struct ScanDetail: Codable {
    let scanId: Int
    let status: String
    let createdAt: Date
}
