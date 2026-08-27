//
//  SelfRepairGuide.swift
//  RoomLog
//
//  Created by wk1717 on 8/26/26.
//

import Foundation

struct SelfRepairGuide: Hashable {
    let defectId: Int
    let isPossible: Bool
    let description: String
    let videos: [SelfRepairVideo]
    let items: [SelfRepairItem]
    let totalCost: Int
}

struct SelfRepairVideo: Hashable {
    let title: String
    let urlString: String
    let channel: String
    let thumbnailURLString: String?
}

struct SelfRepairItem: Hashable {
    let name: String
    let price: Int
    let urlString: String
    let imageURLString: String?
}
