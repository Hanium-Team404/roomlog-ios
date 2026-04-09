//
//  UpdatedRoomDetail.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

// MARK: - Room Detail Edit Model

struct UpdatedRoomDetail: Codable {
    let roomId: Int
    let name: String
    let address: String
    let moveInDate: Date
    let moveOutDate: Date
    let thumbnailURL: String?
}
