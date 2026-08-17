//
//  MockHouseRepository.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
@testable import RoomLog

final class MockHouseRepository: HouseRepositoryProtocol {

    // MARK: - Call Tracking

    var getHousesCallCount = 0
    var createHouseCallCount = 0
    var updateHouseCallCount = 0
    var deleteHouseCallCount = 0
    var setMainHouseCallCount = 0
    var getHouseRoomsCallCount = 0
    var createRoomCallCount = 0

    // MARK: - Captured Arguments

    var lastCreatedHouseName: String?
    var lastCreateArguments: CreateHouseArguments?
    var lastUpdateArguments: UpdateHouseArguments?
    var lastDeletedHouseId: Int?
    var lastMainHouseId: Int?

    struct CreateHouseArguments: Equatable {
        let name: String
        let address: String
        let houseColor: HouseColor
        let floorColor: FloorColor
    }

    struct UpdateHouseArguments: Equatable {
        let houseId: Int
        let name: String
        let address: String
        let houseColor: HouseColor
        let floorColor: FloorColor
    }

    // MARK: - Stub Results

    var getHousesResult: Result<HouseList, Error> = .success(
        HouseList(houses: [], mainHouse: nil, totalCount: 0)
    )
    var createHouseResult: Result<House, Error> = .success(
        House(houseId: 1, name: "테스트 집", address: nil)
    )
    var updateHouseResult: Result<House, Error> = .success(
        House(houseId: 1, name: "수정된 집", address: nil)
    )
    var deleteHouseResult: Result<Void, Error> = .success(())
    var setMainHouseResult: Result<Void, Error> = .success(())
    var getHouseRoomsResult: Result<HouseRooms, Error> = .success(
        HouseRooms(rooms: [], houseId: 1, houseName: "테스트 집", totalCount: 0)
    )
    var createRoomResult: Result<Int, Error> = .success(1)

    // MARK: - HouseRepositoryProtocol

    func getHouses() async throws -> HouseList {
        getHousesCallCount += 1
        return try getHousesResult.get()
    }

    func createHouse(name: String, address: String, houseColor: HouseColor, floorColor: FloorColor) async throws -> House {
        createHouseCallCount += 1
        lastCreatedHouseName = name
        lastCreateArguments = CreateHouseArguments(
            name: name, address: address, houseColor: houseColor, floorColor: floorColor
        )
        return try createHouseResult.get()
    }

    func updateHouse(houseId: Int, name: String, address: String, houseColor: HouseColor, floorColor: FloorColor) async throws -> House {
        updateHouseCallCount += 1
        lastUpdateArguments = UpdateHouseArguments(
            houseId: houseId, name: name, address: address, houseColor: houseColor, floorColor: floorColor
        )
        return try updateHouseResult.get()
    }

    func deleteHouse(houseId: Int) async throws {
        deleteHouseCallCount += 1
        lastDeletedHouseId = houseId
        try deleteHouseResult.get()
    }

    func setMainHouse(houseId: Int) async throws {
        setMainHouseCallCount += 1
        lastMainHouseId = houseId
        try setMainHouseResult.get()
    }

    func getHouseRooms(houseId: Int) async throws -> HouseRooms {
        getHouseRoomsCallCount += 1
        return try getHouseRoomsResult.get()
    }

    func createRoom(houseId: Int, name: String, scanId: Int) async throws -> Int {
        createRoomCallCount += 1
        return try createRoomResult.get()
    }
}
