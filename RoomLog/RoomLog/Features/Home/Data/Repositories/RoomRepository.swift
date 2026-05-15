//
//  RoomRepository.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation
import Moya

final class RoomRepository: RoomRepositoryProtocol {
    // MARK: - Property
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function
    func getRoomDetail(roomId: Int) async throws -> RoomDetail {
        let response = try await adapter.request(RoomTarget.getRoomDetail(roomId: roomId))
        let dto = try decoder.decode(APIResponse<RoomDetailResponseDTO>.self, from: response.data)
        return try dto.unwrap().toDomain()
    }

    func updateRoom(roomId: Int, name: String, moveInDate: Date, moveOutDate: Date?) async throws {
        let body = UpdateRoomRequestDTO(
            name: name,
            moveInDate: moveInDate.toServerDateString(),
            moveOutDate: moveOutDate?.toServerDateString()
        )
        let response = try await adapter.request(RoomTarget.updateRoom(roomId: roomId, request: body))
        let dto = try decoder.decode(APIResponse<UpdateRoomResponseDTO>.self, from: response.data)
        _ = try dto.unwrap()
    }

    func deleteRoom(roomId: Int) async throws {
        let response = try await adapter.request(RoomTarget.deleteRoom(roomId: roomId))
        let dto = try decoder.decode(APIResponse<DeleteRoomResponseDTO>.self, from: response.data)
        _ = try dto.unwrap()
    }
}
