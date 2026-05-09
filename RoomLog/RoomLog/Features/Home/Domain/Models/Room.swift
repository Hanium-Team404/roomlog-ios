//
//  Room.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

// MARK: - Room Summary (목록용)

struct RoomSummary: Identifiable {
    let id: Int
    let name: String
    let thumbnailURL: String?
    let latestScan: LatestScan?
    let recentScanDate: Date?
    let latestScanStatus: String?
}

struct LatestScan {
    let scanId: Int
    let scanType: String
}

// MARK: - Room Detail (상세 조회용)

struct RoomDetail: Identifiable {
    let id: Int
    let name: String
    let address: String?
    let moveInDate: Date?
    let moveOutDate: Date?
    let thumbnailURL: String?
    let fileURL: String?
    let createdAt: Date
    let latestScan: ScanDetail?
}

struct ScanDetail {
    let scanId: Int
    let status: String
    let createdAt: Date
}
