//
//  MockHomeUseCaseProvider.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
@testable import RoomLog

final class MockHomeUseCaseProvider: HomeUseCaseProvider {

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
    var createRoomResult: Result<Void, Error> = .success(())
    var getRoomDetailResult: Result<RoomDetail, Error> = .success(
        RoomDetail(id: 1, name: "테스트 방", moveInDate: nil, moveOutDate: nil,
                   thumbnailURL: nil, fileURL: nil, createdAt: Date(), latestScan: nil)
    )
    var updateRoomResult: Result<Void, Error> = .success(())
    var deleteRoomResult: Result<Void, Error> = .success(())

    // MARK: - HomeUseCaseProvider

    func makeGetHousesUseCase() -> GetHousesUseCaseProtocol {
        StubGetHousesUseCase(result: getHousesResult)
    }
    func makeCreateHouseUseCase() -> CreateHouseUseCaseProtocol {
        StubCreateHouseUseCase(result: createHouseResult)
    }
    func makeUpdateHouseUseCase() -> UpdateHouseUseCaseProtocol {
        StubUpdateHouseUseCase(result: updateHouseResult)
    }
    func makeDeleteHouseUseCase() -> DeleteHouseUseCaseProtocol {
        StubDeleteHouseUseCase(result: deleteHouseResult)
    }
    func makeSetMainHouseUseCase() -> SetMainHouseUseCaseProtocol {
        StubSetMainHouseUseCase(result: setMainHouseResult)
    }
    func makeGetHouseRoomsUseCase() -> GetHouseRoomsUseCaseProtocol {
        StubGetHouseRoomsUseCase(result: getHouseRoomsResult)
    }
    func makeCreateRoomUseCase() -> CreateRoomUseCaseProtocol {
        StubCreateRoomUseCase(result: createRoomResult)
    }
    func makeGetRoomDetailUseCase() -> GetRoomDetailUseCaseProtocol {
        StubGetRoomDetailUseCase(result: getRoomDetailResult)
    }
    func makeUpdateRoomUseCase() -> UpdateRoomUseCaseProtocol {
        StubUpdateRoomUseCase(result: updateRoomResult)
    }
    func makeDeleteRoomUseCase() -> DeleteRoomUseCaseProtocol {
        StubDeleteRoomUseCase(result: deleteRoomResult)
    }
}

// MARK: - Stub UseCases

private struct StubGetHousesUseCase: GetHousesUseCaseProtocol {
    let result: Result<HouseList, Error>
    func execute() async throws -> HouseList { try result.get() }
}

private struct StubCreateHouseUseCase: CreateHouseUseCaseProtocol {
    let result: Result<House, Error>
    func execute(name: String, address: String?) async throws -> House { try result.get() }
}

private struct StubUpdateHouseUseCase: UpdateHouseUseCaseProtocol {
    let result: Result<House, Error>
    func execute(houseId: Int, name: String, address: String?) async throws -> House { try result.get() }
}

private struct StubDeleteHouseUseCase: DeleteHouseUseCaseProtocol {
    let result: Result<Void, Error>
    func execute(houseId: Int) async throws { try result.get() }
}

private struct StubSetMainHouseUseCase: SetMainHouseUseCaseProtocol {
    let result: Result<Void, Error>
    func execute(houseId: Int) async throws { try result.get() }
}

private struct StubGetHouseRoomsUseCase: GetHouseRoomsUseCaseProtocol {
    let result: Result<HouseRooms, Error>
    func execute(houseId: Int) async throws -> HouseRooms { try result.get() }
}

private struct StubCreateRoomUseCase: CreateRoomUseCaseProtocol {
    let result: Result<Void, Error>
    func execute(houseId: Int, name: String, scanId: Int) async throws { try result.get() }
}

private struct StubGetRoomDetailUseCase: GetRoomDetailUseCaseProtocol {
    let result: Result<RoomDetail, Error>
    func execute(roomId: Int) async throws -> RoomDetail { try result.get() }
}

private struct StubUpdateRoomUseCase: UpdateRoomUseCaseProtocol {
    let result: Result<Void, Error>
    func execute(roomId: Int, name: String, moveInDate: Date, moveOutDate: Date?) async throws { try result.get() }
}

private struct StubDeleteRoomUseCase: DeleteRoomUseCaseProtocol {
    let result: Result<Void, Error>
    func execute(roomId: Int) async throws { try result.get() }
}
