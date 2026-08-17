//
//  HomeViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Testing
import Foundation
@testable import RoomLog

@MainActor
struct HomeViewModelTests {

    private let provider: MockHomeUseCaseProvider
    private let sut: HomeViewModel

    init() {
        provider = MockHomeUseCaseProvider()
        sut = HomeViewModel(provider: provider)
    }

    // MARK: - fetchHouses

    @Test func fetchHouses_성공시_houses와_mainHouse가_설정된다() async {
        let mainHouse = House(houseId: 1, name: "본가", address: "서울")
        let houses = [mainHouse, House(houseId: 2, name: "자취방", address: nil)]
        provider.getHousesResult = .success(
            HouseList(houses: houses, mainHouse: mainHouse, totalCount: 2)
        )

        await sut.fetchHouses()

        #expect(sut.houses.count == 2)
        #expect(sut.mainHouse?.houseId == 1)
        #expect(!sut.isLoading)
        #expect(sut.errorMessage == nil)
    }

    @Test func fetchHouses_실패시_errorMessage가_설정된다() async {
        provider.getHousesResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "서버 오류"]))

        await sut.fetchHouses()

        #expect(sut.houses.isEmpty)
        #expect(sut.mainHouse == nil)
        #expect(!sut.isLoading)
        #expect(sut.errorMessage == "서버 오류")
    }

    @Test func fetchHouses_빈_목록일때_houses가_비어있고_에러가_없다() async {
        provider.getHousesResult = .success(
            HouseList(houses: [], mainHouse: nil, totalCount: 0)
        )

        await sut.fetchHouses()

        #expect(sut.houses.isEmpty)
        #expect(sut.mainHouse == nil)
        #expect(!sut.isLoading)
        #expect(sut.errorMessage == nil)
    }

    @Test func fetchHouses_재호출시_errorMessage가_초기화된다() async {
        provider.getHousesResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "서버 오류"]))
        await sut.fetchHouses()
        #expect(sut.errorMessage == "서버 오류")

        provider.getHousesResult = .success(
            HouseList(houses: [House(houseId: 1, name: "본가", address: nil)], mainHouse: nil, totalCount: 1)
        )
        await sut.fetchHouses()

        #expect(sut.errorMessage == nil)
        #expect(sut.houses.count == 1)
    }

    // MARK: - createHouse

    @Test func createHouse_성공시_houses에_추가된다() async throws {
        let newHouse = House(houseId: 3, name: "새 집", address: "서울")
        provider.createHouseResult = .success(newHouse)

        try await sut.createHouse(name: "새 집", address: "서울")

        #expect(sut.houses.count == 1)
        #expect(sut.houses.first?.name == "새 집")
    }

    @Test func createHouse_실패시_에러를_던진다() async {
        provider.createHouseResult = .failure(NSError(domain: "test", code: -1))

        await #expect(throws: (any Error).self) {
            try await sut.createHouse(name: "실패", address: "서울")
        }
        #expect(sut.houses.isEmpty)
    }

    @Test func createHouse_기존_목록이_있을때_맨_뒤에_추가된다() async throws {
        provider.getHousesResult = .success(
            HouseList(houses: [House(houseId: 1, name: "본가", address: nil)], mainHouse: nil, totalCount: 1)
        )
        await sut.fetchHouses()

        provider.createHouseResult = .success(House(houseId: 2, name: "자취방", address: "부산"))
        try await sut.createHouse(name: "자취방", address: "부산")

        #expect(sut.houses.count == 2)
        #expect(sut.houses.last?.houseId == 2)
        #expect(sut.houses.first?.houseId == 1)
    }

    @Test func createHouse_이름_주소_색상이_그대로_유즈케이스로_전달된다() async throws {
        provider.createHouseResult = .success(
            House(houseId: 3, name: "새 집", address: "서울", houseColor: .navy, floorColor: .pink)
        )

        try await sut.createHouse(name: "새 집", address: "서울", houseColor: .navy, floorColor: .pink)

        #expect(
            provider.lastCreateHouseArguments == MockHomeUseCaseProvider.CreateHouseArguments(
                name: "새 집", address: "서울", houseColor: .navy, floorColor: .pink
            )
        )
    }

    @Test func createHouse_색상을_생략하면_기본_색상이_전달된다() async throws {
        try await sut.createHouse(name: "새 집", address: "서울")

        #expect(provider.lastCreateHouseArguments?.houseColor == .fallback)
        #expect(provider.lastCreateHouseArguments?.floorColor == .fallback)
    }

    @Test func createHouse_성공시_서버가_준_색상이_houses에_반영된다() async throws {
        provider.createHouseResult = .success(
            House(houseId: 3, name: "새 집", address: "서울", houseColor: .olive, floorColor: .gray)
        )

        try await sut.createHouse(name: "새 집", address: "서울", houseColor: .olive, floorColor: .gray)

        #expect(sut.houses.first?.houseColor == .olive)
        #expect(sut.houses.first?.floorColor == .gray)
    }
}
