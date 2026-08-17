//
//  HouseDTOTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 8/17/26.
//

import Testing
import Foundation
@testable import RoomLog

struct HouseDTOTests {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - Response → Domain

    @Test func houseSummaryDTO_색상_키가_도메인_색상으로_매핑된다() throws {
        let json = """
        {
            "house_id": 1,
            "name": "본가",
            "address": "서울시 중구",
            "house_color": "navy",
            "floor_color": "blueGray"
        }
        """
        let dto = try decoder.decode(HouseSummaryDTO.self, from: Data(json.utf8))

        let house = dto.toDomain()

        #expect(house.houseColor == .navy)
        #expect(house.floorColor == .blueGray)
    }

    @Test func houseSummaryDTO_색상_필드가_없으면_nil로_매핑된다() throws {
        let json = """
        {
            "house_id": 1,
            "name": "본가",
            "address": "서울시 중구"
        }
        """
        let dto = try decoder.decode(HouseSummaryDTO.self, from: Data(json.utf8))

        let house = dto.toDomain()

        #expect(house.houseColor == nil)
        #expect(house.floorColor == nil)
    }

    @Test func houseSummaryDTO_색상이_null이면_nil로_매핑된다() throws {
        let json = """
        {
            "house_id": 1,
            "name": "본가",
            "address": null,
            "house_color": null,
            "floor_color": null
        }
        """
        let dto = try decoder.decode(HouseSummaryDTO.self, from: Data(json.utf8))

        let house = dto.toDomain()

        #expect(house.address == nil)
        #expect(house.houseColor == nil)
        #expect(house.floorColor == nil)
    }

    /// 앱이 모르는 색상 키가 내려와도 디코딩이 실패하지 않고 nil(기본 색상 폴백)로 처리되어야 한다.
    @Test func houseSummaryDTO_모르는_색상_키는_nil로_매핑된다() throws {
        let json = """
        {
            "house_id": 1,
            "name": "본가",
            "address": "서울시 중구",
            "house_color": "hotpink",
            "floor_color": "chartreuse"
        }
        """
        let dto = try decoder.decode(HouseSummaryDTO.self, from: Data(json.utf8))

        let house = dto.toDomain()

        #expect(house.houseColor == nil)
        #expect(house.floorColor == nil)
    }

    // MARK: - Request 인코딩

    @Test func createHouseRequestDTO가_snake_case_키로_인코딩된다() throws {
        let body = CreateHouseRequestDTO(
            name: "새 집",
            address: "서울시 강남구",
            houseColor: HouseColor.terracotta.rawValue,
            floorColor: FloorColor.peach.rawValue
        )

        let data = try encoder.encode(body)
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: String]
        )

        #expect(json["name"] == "새 집")
        #expect(json["address"] == "서울시 강남구")
        #expect(json["house_color"] == "terracotta")
        #expect(json["floor_color"] == "peach")
    }

    @Test func updateHouseRequestDTO가_snake_case_키로_인코딩된다() throws {
        let body = UpdateHouseRequestDTO(
            name: "수정된 집",
            address: "부산시 해운대구",
            houseColor: HouseColor.olive.rawValue,
            floorColor: FloorColor.gray.rawValue
        )

        let data = try encoder.encode(body)
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: String]
        )

        #expect(json["name"] == "수정된 집")
        #expect(json["address"] == "부산시 해운대구")
        #expect(json["house_color"] == "olive")
        #expect(json["floor_color"] == "gray")
    }

    // MARK: - 서버 규약

    /// rawValue는 서버에 저장되는 색상 키이므로 case 이름을 바꾸면 기존 데이터와 어긋난다.
    @Test func 색상_rawValue가_서버_규약과_일치한다() {
        #expect(HouseColor.allCases.map(\.rawValue) == ["blue", "beige", "terracotta", "olive", "navy"])
        #expect(FloorColor.allCases.map(\.rawValue) == ["beige", "blueGray", "peach", "pink", "gray"])
        #expect(HouseColor.fallback == .blue)
        #expect(FloorColor.fallback == .beige)
    }
}
