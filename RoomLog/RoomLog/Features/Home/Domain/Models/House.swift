//
//  House.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import Foundation

/// 순수 값 모델. 직접 선언한 init이 기본 격리(MainActor)를 받으면 테스트 Mock의 기본값처럼
/// nonisolated 문맥에서 만들 수 없으므로(Xcode 26.6 기준 에러) 색상 enum과 같이 격리에서 제외한다
nonisolated struct House: Hashable, Identifiable {
    var id: Int { houseId }
    let houseId: Int
    let name: String
    let address: String?
    let houseColor: HouseColor?
    let floorColor: FloorColor?

    init(
        houseId: Int,
        name: String,
        address: String?,
        houseColor: HouseColor? = nil,
        floorColor: FloorColor? = nil
    ) {
        self.houseId = houseId
        self.name = name
        self.address = address
        self.houseColor = houseColor
        self.floorColor = floorColor
    }
}

/// 집 아이콘의 건물(지붕) 색상. rawValue가 서버에 저장되는 색상 키.
nonisolated enum HouseColor: String, CaseIterable, Hashable {
    case blue, beige, terracotta, olive, navy

    /// 색상 정보가 없는 기존 집에 사용하는 기본값
    static let fallback: HouseColor = .blue
}

/// 집 아이콘의 바닥 색상. rawValue가 서버에 저장되는 색상 키.
nonisolated enum FloorColor: String, CaseIterable, Hashable {
    case beige, blueGray, peach, pink, gray

    /// 색상 정보가 없는 기존 집에 사용하는 기본값
    static let fallback: FloorColor = .beige
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
