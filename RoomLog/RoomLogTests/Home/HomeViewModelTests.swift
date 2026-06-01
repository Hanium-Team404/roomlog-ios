//
//  HomeViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import XCTest
@testable import RoomLog

@MainActor
final class HomeViewModelTests: XCTestCase {

    private var provider: MockHomeUseCaseProvider!
    private var sut: HomeViewModel!

    override func setUp() {
        super.setUp()
        provider = MockHomeUseCaseProvider()
        sut = HomeViewModel(provider: provider)
    }

    // MARK: - fetchHouses

    func test_fetchHouses_성공시_houses와_mainHouse가_설정된다() async {
        let mainHouse = House(houseId: 1, name: "본가", address: "서울")
        let houses = [mainHouse, House(houseId: 2, name: "자취방", address: nil)]
        provider.getHousesResult = .success(
            HouseList(houses: houses, mainHouse: mainHouse, totalCount: 2)
        )

        await sut.fetchHouses()

        XCTAssertEqual(sut.houses.count, 2)
        XCTAssertEqual(sut.mainHouse?.houseId, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_fetchHouses_실패시_errorMessage가_설정된다() async {
        provider.getHousesResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "서버 오류"]))

        await sut.fetchHouses()

        XCTAssertTrue(sut.houses.isEmpty)
        XCTAssertNil(sut.mainHouse)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "서버 오류")
    }

    // MARK: - createHouse

    func test_createHouse_성공시_houses에_추가된다() async throws {
        let newHouse = House(houseId: 3, name: "새 집", address: nil)
        provider.createHouseResult = .success(newHouse)

        try await sut.createHouse(name: "새 집", address: nil)

        XCTAssertEqual(sut.houses.count, 1)
        XCTAssertEqual(sut.houses.first?.name, "새 집")
    }

    func test_createHouse_실패시_에러를_던진다() async {
        provider.createHouseResult = .failure(NSError(domain: "test", code: -1))

        do {
            try await sut.createHouse(name: "실패", address: nil)
            XCTFail("에러가 발생해야 합니다")
        } catch {
            XCTAssertTrue(sut.houses.isEmpty)
        }
    }
}
