//
//  HouseRepository.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation
import Moya

final class HouseRepository: HouseRepositoryProtocol {
    // MARK: - Property
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function
    func getHouses() async throws -> HouseList {
        let response = try await adapter.request(HouseTarget.getHouses)
        let dto = try decoder.decode(APIResponse<GetHousesResponseDTO>.self, from: response.data)
        let result = try dto.unwrap()
        return HouseList(
            houses: result.houses.map { $0.toDomain() },
            mainHouse: result.mainHouse?.toDomain(),
            totalCount: result.totalCount
        )
    }

    func createHouse(name: String, address: String, houseColor: HouseColor, floorColor: FloorColor) async throws -> House {
        let body = CreateHouseRequestDTO(
            name: name,
            address: address,
            houseColor: houseColor.rawValue,
            floorColor: floorColor.rawValue
        )
        let response = try await adapter.request(HouseTarget.createHouse(request: body))
        let dto = try decoder.decode(APIResponse<CreateHouseResponseDTO>.self, from: response.data)
        let result = try dto.unwrap()
        return House(
            houseId: result.houseId,
            name: result.name,
            address: result.address,
            houseColor: result.houseColor.flatMap(HouseColor.init(rawValue:)),
            floorColor: result.floorColor.flatMap(FloorColor.init(rawValue:))
        )
    }

    func updateHouse(houseId: Int, name: String, address: String, houseColor: HouseColor, floorColor: FloorColor) async throws -> House {
        let body = UpdateHouseRequestDTO(
            name: name,
            address: address,
            houseColor: houseColor.rawValue,
            floorColor: floorColor.rawValue
        )
        let response = try await adapter.request(HouseTarget.updateHouse(houseId: houseId, request: body))
        let dto = try decoder.decode(APIResponse<UpdateHouseResponseDTO>.self, from: response.data)
        let result = try dto.unwrap()
        return House(
            houseId: result.houseId,
            name: result.name,
            address: result.address,
            houseColor: result.houseColor.flatMap(HouseColor.init(rawValue:)),
            floorColor: result.floorColor.flatMap(FloorColor.init(rawValue:))
        )
    }

    func deleteHouse(houseId: Int) async throws {
        let response = try await adapter.request(HouseTarget.deleteHouse(houseId: houseId))
        let dto = try decoder.decode(APIResponse<DeleteHouseResponseDTO>.self, from: response.data)
        _ = try dto.unwrap()
    }

    func setMainHouse(houseId: Int) async throws {
        let response = try await adapter.request(HouseTarget.setMainHouse(houseId: houseId))
        let dto = try decoder.decode(APIResponse<SetMainHouseResponseDTO>.self, from: response.data)
        _ = try dto.unwrap()
    }

    func getHouseRooms(houseId: Int) async throws -> HouseRooms {
        let response = try await adapter.request(HouseTarget.getHouseRooms(houseId: houseId))
        let dto = try decoder.decode(APIResponse<GetHouseRoomsResponseDTO>.self, from: response.data)
        let result = try dto.unwrap()
        return HouseRooms(
            rooms: result.rooms.map { $0.toDomain() },
            houseId: result.houseId,
            houseName: result.houseName,
            totalCount: result.totalCount
        )
    }

    func createRoom(houseId: Int, name: String, scanId: Int) async throws -> Int {
        let body = CreateRoomRequestDTO(name: name, scanId: scanId)
        let response = try await adapter.request(HouseTarget.createRoom(houseId: houseId, request: body))
        let dto = try decoder.decode(APIResponse<CreateRoomResponseDTO>.self, from: response.data)
        return try dto.unwrap().roomId
    }
}
