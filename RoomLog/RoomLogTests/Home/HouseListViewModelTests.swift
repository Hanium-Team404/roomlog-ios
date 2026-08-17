//
//  HouseListViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import XCTest
@testable import RoomLog

@MainActor
final class HouseListViewModelTests: XCTestCase {

    private var provider: MockHomeUseCaseProvider!
    private var sut: HouseListViewModel!

    override func setUp() {
        super.setUp()
        provider = MockHomeUseCaseProvider()
        sut = HouseListViewModel(provider: provider)
    }

    // MARK: - fetchHouses

    func test_fetchHouses_성공시_houses와_mainHouse가_설정된다() async {
        let main = House(houseId: 1, name: "본가", address: "서울")
        provider.getHousesResult = .success(
            HouseList(houses: [main], mainHouse: main, totalCount: 1)
        )

        await sut.fetchHouses()

        XCTAssertEqual(sut.houses.count, 1)
        XCTAssertEqual(sut.mainHouse?.houseId, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_fetchHouses_실패시_errorMessage가_설정된다() async {
        provider.getHousesResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "서버 오류"]))

        await sut.fetchHouses()

        XCTAssertTrue(sut.houses.isEmpty)
        XCTAssertEqual(sut.errorMessage, "서버 오류")
    }

    // MARK: - setMainHouse

    func test_setMainHouse_성공시_mainHouse가_변경된다() async {
        let house1 = House(houseId: 1, name: "집1", address: nil)
        let house2 = House(houseId: 2, name: "집2", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house1, house2], mainHouse: house1, totalCount: 2)
        )
        await sut.fetchHouses()

        sut.selectedHouseId = 2
        await sut.setMainHouse()

        XCTAssertEqual(sut.mainHouse?.houseId, 2)
        XCTAssertFalse(sut.isEditing)
        XCTAssertTrue(sut.showSetMainSuccess)
    }

    func test_setMainHouse_selectedId가_nil이면_아무것도_안한다() async {
        sut.selectedHouseId = nil

        await sut.setMainHouse()

        XCTAssertNil(sut.mainHouse)
        XCTAssertFalse(sut.showSetMainSuccess)
    }

    func test_setMainHouse_실패시_errorMessage가_설정된다() async {
        let house = House(houseId: 1, name: "집", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: nil, totalCount: 1)
        )
        await sut.fetchHouses()
        provider.setMainHouseResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "권한 없음"]))
        sut.selectedHouseId = 1

        await sut.setMainHouse()

        XCTAssertEqual(sut.errorMessage, "권한 없음")
    }

    // MARK: - updateHouse

    func test_updateHouse_성공시_목록과_mainHouse가_갱신된다() async throws {
        let house = House(houseId: 1, name: "원래 이름", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: house, totalCount: 1)
        )
        await sut.fetchHouses()

        let updated = House(houseId: 1, name: "새 이름", address: "부산")
        provider.updateHouseResult = .success(updated)

        try await sut.updateHouse(houseId: 1, name: "새 이름", address: "부산")

        XCTAssertEqual(sut.houses.first?.name, "새 이름")
        XCTAssertEqual(sut.mainHouse?.name, "새 이름")
    }

    func test_updateHouse_선택한_색상이_그대로_유즈케이스로_전달된다() async throws {
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

        XCTAssertEqual(
            provider.lastUpdateHouseArguments,
            MockHomeUseCaseProvider.UpdateHouseArguments(
                houseId: 1, name: "새 이름", address: "부산",
                houseColor: .olive, floorColor: .gray
            )
        )
        XCTAssertEqual(sut.houses.first?.houseColor, .olive)
        XCTAssertEqual(sut.mainHouse?.floorColor, .gray)
    }

    func test_updateHouse_색상을_생략하면_기본_색상이_전달된다() async throws {
        try await sut.updateHouse(houseId: 1, name: "새 이름", address: "부산")

        XCTAssertEqual(provider.lastUpdateHouseArguments?.houseColor, .fallback)
        XCTAssertEqual(provider.lastUpdateHouseArguments?.floorColor, .fallback)
    }

    // MARK: - deleteSelectedHouse

    func test_deleteSelectedHouse_성공시_목록에서_제거된다() async {
        let house = House(houseId: 1, name: "삭제할 집", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: nil, totalCount: 1)
        )
        await sut.fetchHouses()
        sut.selectedHouseId = 1

        await sut.deleteSelectedHouse()

        XCTAssertTrue(sut.houses.isEmpty)
        XCTAssertNil(sut.selectedHouseId)
        XCTAssertFalse(sut.isEditing)
    }

    func test_deleteSelectedHouse_실패시_errorMessage가_설정된다() async {
        let house = House(houseId: 1, name: "집", address: nil)
        provider.getHousesResult = .success(
            HouseList(houses: [house], mainHouse: nil, totalCount: 1)
        )
        await sut.fetchHouses()
        provider.deleteHouseResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "삭제 실패"]))
        sut.selectedHouseId = 1

        await sut.deleteSelectedHouse()

        XCTAssertEqual(sut.errorMessage, "삭제 실패")
        XCTAssertEqual(sut.houses.count, 1)
    }

    // MARK: - isEditing

    func test_isEditing_true시_selectedHouseId가_nil로_초기화된다() {
        sut.selectedHouseId = 5

        sut.isEditing = true

        XCTAssertNil(sut.selectedHouseId)
    }
}
