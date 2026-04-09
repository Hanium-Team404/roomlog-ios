//
//  HomeRepository.swift
//  RoomLog
//
//  Created by 김도연 on 4/9/26.
//

import Foundation
import Moya

final class HomeRepository: HomeRepositoryProtocol {
    // MARK: - Property
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function
    func getHomeData() async throws -> HomeData {
        let response = try await adapter.request(RoomTarget.getHomeData)
        let dto = try decoder.decode(APIResponse<HomeDataResponseDTO>.self, from: response.data)
        let result = try dto.unwrap()
        return HomeData(
            mainRoom: result.mainRoom.toDomain(),
            rooms: result.rooms.map { $0.toDomain() },
            totalCount: result.totalCount
        )
    }

    func getRoomDetail(roomId: Int) async throws -> RoomDetail {
        let response = try await adapter.request(RoomTarget.getRoomDetail(roomId: roomId))
        let dto = try decoder.decode(APIResponse<RoomDetailResponseDTO>.self, from: response.data)
        return try dto.unwrap().toDomain()
    }

    func patchRoom(request: UpdatedRoomDetail) async throws -> UpdatedRoomDetail {
        let body = PatchRoomRequestDTO(
            name: request.name,
            address: request.address,
            moveInDate: request.moveInDate.toServerDateString(),
            moveOutDate: request.moveOutDate.toServerDateString()
        )
        let response = try await adapter.request(RoomTarget.patchRoom(roomId: request.roomId, request: body))
        let dto = try decoder.decode(APIResponse<UpdatedRoomDetailResponseDTO>.self, from: response.data)
        return try dto.unwrap().toDomain()
    }

    func deleteRoom(roomId: Int) async throws {
        let response = try await adapter.request(RoomTarget.deleteRoom(roomId: roomId))
        let dto = try decoder.decode(APIResponse<EmptyResult>.self, from: response.data)
        _ = try dto.unwrap()
    }

    func patchMainRoom(roomId: Int) async throws {
        let response = try await adapter.request(RoomTarget.patchMainRoom(roomId: roomId))
        let dto = try decoder.decode(APIResponse<EmptyResult>.self, from: response.data)
        _ = try dto.unwrap()
    }
}
