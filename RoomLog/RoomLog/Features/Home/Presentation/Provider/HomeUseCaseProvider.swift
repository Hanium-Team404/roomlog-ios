//
//  HomeUseCaseProvider.swift
//  RoomLog
//
//  Created by 김도연 on 4/14/26.
//

import Foundation

protocol HomeUseCaseProvider {
    // MARK: - House
    func makeGetHousesUseCase() -> GetHousesUseCaseProtocol
    func makeCreateHouseUseCase() -> CreateHouseUseCaseProtocol
    func makeUpdateHouseUseCase() -> UpdateHouseUseCaseProtocol
    func makeDeleteHouseUseCase() -> DeleteHouseUseCaseProtocol
    func makeSetMainHouseUseCase() -> SetMainHouseUseCaseProtocol
    func makeGetHouseRoomsUseCase() -> GetHouseRoomsUseCaseProtocol
    func makeCreateRoomUseCase() -> CreateRoomUseCaseProtocol

    // MARK: - Room
    func makeGetRoomDetailUseCase() -> GetRoomDetailUseCaseProtocol
    func makeUpdateRoomUseCase() -> UpdateRoomUseCaseProtocol
    func makeDeleteRoomUseCase() -> DeleteRoomUseCaseProtocol
}

final class HomeUseCaseProviderImpl: HomeUseCaseProvider {
    // MARK: - Repository
    private let houseRepository: HouseRepositoryProtocol
    private let roomRepository: RoomRepositoryProtocol

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter) {
        self.houseRepository = HouseRepository(adapter: adapter)
        self.roomRepository = RoomRepository(adapter: adapter)
    }

    // MARK: - House UseCases
    func makeGetHousesUseCase() -> GetHousesUseCaseProtocol {
        GetHousesUseCase(repository: houseRepository)
    }

    func makeCreateHouseUseCase() -> CreateHouseUseCaseProtocol {
        CreateHouseUseCase(repository: houseRepository)
    }

    func makeUpdateHouseUseCase() -> UpdateHouseUseCaseProtocol {
        UpdateHouseUseCase(repository: houseRepository)
    }

    func makeDeleteHouseUseCase() -> DeleteHouseUseCaseProtocol {
        DeleteHouseUseCase(repository: houseRepository)
    }

    func makeSetMainHouseUseCase() -> SetMainHouseUseCaseProtocol {
        SetMainHouseUseCase(repository: houseRepository)
    }

    func makeGetHouseRoomsUseCase() -> GetHouseRoomsUseCaseProtocol {
        GetHouseRoomsUseCase(repository: houseRepository)
    }

    func makeCreateRoomUseCase() -> CreateRoomUseCaseProtocol {
        CreateRoomUseCase(repository: houseRepository)
    }

    // MARK: - Room UseCases
    func makeGetRoomDetailUseCase() -> GetRoomDetailUseCaseProtocol {
        GetRoomDetailUseCase(repository: roomRepository)
    }

    func makeUpdateRoomUseCase() -> UpdateRoomUseCaseProtocol {
        UpdateRoomUseCase(repository: roomRepository)
    }

    func makeDeleteRoomUseCase() -> DeleteRoomUseCaseProtocol {
        DeleteRoomUseCase(repository: roomRepository)
    }
}
