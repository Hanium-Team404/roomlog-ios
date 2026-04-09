//
//  HomeData.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

// MARK: - Home MainView Model

struct HomeData: Codable {
    let mainRoom: RoomSummary
    let rooms: [RoomSummary]
    let totalCount: Int
}

struct RoomSummary: Codable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let thumbnailURL: String?
    let latestScan: LatestScan?
    let moveInDate: Date?
    let moveOutDate: Date?
    let recentScanDate: Date?
    let latestScanStatus: String?
}

struct LatestScan: Codable {
    let scanId: Int
    let scanType: String
}
