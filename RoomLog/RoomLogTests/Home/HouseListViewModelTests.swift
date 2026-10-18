//
//  HouseListViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
import Testing
@testable import RoomLog

@MainActor
struct HouseListViewModelTests {

    private let provider: MockHomeUseCaseProvider
    private let sut: HouseListViewModel

    init() {
        provider = MockHomeUseCaseProvider()
        sut = HouseListViewModel(provider: provider)
    }

    // MARK: - fetchHouses

    @Test
    func fetchHouses_성공시_houses와_mainHouse가_설정된다() async {
        let main = House(houseId: 1, name: "본가", address: "서울")
        provider.getHousesResult = .success(
            HouseList(houses: [main], mainHouse: main, totalCount: 1)
        )

        await sut.fetchHouses()

        #expect(sut.houses.count == 1)
        #expect(sut.mainHouse?.houseId == 1)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test
    func fetchHouses_실패시_errorMessage가_설정된다() async {
        provider.getHousesResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "서버 오류"]))

        await sut.fetchHouses()

        #expect(sut.houses.isEmpty)
        #expect(sut.errorMessage == "서버 오류")
    }

    // MARK: - setMainHouse

    @Test
    func setMainHouse_성공시_mainHouse가_변경된다() async {
        let house1 = House(houseId: 1, name: "집1", address: nil)
        let house2 = House(houseId: 2, name: "집2", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house1, house2], mainHouse: house1, totalCount: 2)
        )
        await sut.fetchHouses()

        sut.selectedHouseId = 2
        await sut.setMainHouse()

        #expect(sut.mainHouse?.houseId == 2)
        #expect(sut.isEditing == false)
        #expect(sut.showSetMainSuccess)
    }

    @Test
    func setMainHouse_selectedId가_nil이면_아무것도_안한다() async {
        // use case가 호출되면 errorMessage가 설정되도록 스텁 — guard가 실제로 호출을 막는지 증명
        provider.setMainHouseResult = .failure(NSError(domain: "test", code: -1))
        sut.selectedHouseId = nil

        await sut.setMainHouse()

        #expect(sut.mainHouse == nil)
        #expect(sut.showSetMainSuccess == false)
        #expect(sut.errorMessage == nil)
    }

    @Test
    func setMainHouse_실패시_errorMessage가_설정된다() async {
        let house = House(houseId: 1, name: "집", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: nil, totalCount: 1)
        )
        await sut.fetchHouses()
        provider.setMainHouseResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "권한 없음"]))
        sut.selectedHouseId = 1

        await sut.setMainHouse()

        #expect(sut.errorMessage == "권한 없음")
    }

    // MARK: - updateHouse

    @Test
    func updateHouse_성공시_목록과_mainHouse가_갱신된다() async throws {
        let house = House(houseId: 1, name: "원래 이름", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: house, totalCount: 1)
        )
        await sut.fetchHouses()

        let updated = House(houseId: 1, name: "새 이름", address: "부산")
        provider.updateHouseResult = .success(updated)

        try await sut.updateHouse(houseId: 1, name: "새 이름", address: "부산")

        #expect(sut.houses.first?.name == "새 이름")
        #expect(sut.mainHouse?.name == "새 이름")
    }

    @Test
    func updateHouse_선택한_색상이_그대로_유즈케이스로_전달된다() async throws {
        let house = House(houseId: 1, name: "원래 이름", address: "서울", houseColor: .blue, floorColor: .beige)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: house, totalCount: 1)
        )
        await sut.fetchHouses()

        provider.updateHouseResult = .success(
            House(houseId: 1, name: "새 이름", address: "부산", houseColor: .olive, floorColor: .gray)
        )

        try await sut.updateHouse(
            houseId: 1, name: "새 이름", address: "부산",
            houseColor: .olive, floorColor: .gray
        )

        #expect(
            provider.lastUpdateHouseArguments
                == MockHomeUseCaseProvider.UpdateHouseArguments(
                    houseId: 1, name: "새 이름", address: "부산",
                    houseColor: .olive, floorColor: .gray
                )
        )
        #expect(sut.houses.first?.houseColor == .olive)
        #expect(sut.mainHouse?.floorColor == .gray)
    }

    @Test
    func updateHouse_색상을_생략하면_기본_색상이_전달된다() async throws {
        try await sut.updateHouse(houseId: 1, name: "새 이름", address: "부산")

        #expect(provider.lastUpdateHouseArguments?.houseColor == .fallback)
        #expect(provider.lastUpdateHouseArguments?.floorColor == .fallback)
    }

    // MARK: - deleteSelectedHouse

    @Test
    func deleteSelectedHouse_성공시_목록에서_제거된다() async {
        let house = House(houseId: 1, name: "삭제할 집", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: nil, totalCount: 1)
        )
        await sut.fetchHouses()
        sut.selectedHouseId = 1

        await sut.deleteSelectedHouse()

        #expect(sut.houses.isEmpty)
        #expect(sut.selectedHouseId == nil)
        #expect(sut.isEditing == false)
    }

    @Test
    func deleteSelectedHouse_실패시_errorMessage가_설정된다() async {
        let house = House(houseId: 1, name: "집", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: nil, totalCount: 1)
        )
        await sut.fetchHouses()
        provider.deleteHouseResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "삭제 실패"]))
        sut.selectedHouseId = 1

        await sut.deleteSelectedHouse()

        #expect(sut.errorMessage == "삭제 실패")
        #expect(sut.houses.count == 1)
    }

    // MARK: - isEditing

    @Test
    func isEditing_true시_selectedHouseId가_nil로_초기화된다() {
        sut.selectedHouseId = 5

        sut.isEditing = true

        #expect(sut.selectedHouseId == nil)
    }
}
