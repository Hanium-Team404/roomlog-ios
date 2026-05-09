//
//  House.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import Foundation

struct House: Hashable, Identifiable {
    var id: Int { houseId }
    let houseId: Int
    let name: String
}

struct HouseList {
    let houses: [House]
    let mainHouse: House?
    let totalCount: Int
}

struct HouseRooms {
    let rooms: [RoomSummary]
    let houseId: Int
    let houseName: String
    let totalCount: Int
}
