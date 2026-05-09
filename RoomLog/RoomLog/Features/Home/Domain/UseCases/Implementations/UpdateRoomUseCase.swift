//
//  UpdateRoomUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

final class UpdateRoomUseCase: UpdateRoomUseCaseProtocol {
    private let repository: RoomRepositoryProtocol

    init(repository: RoomRepositoryProtocol) {
        self.repository = repository
    }

    func execute(roomId: Int, name: String, address: String, moveInDate: Date, moveOutDate: Date?) async throws {
        try await repository.updateRoom(roomId: roomId, name: name, address: address, moveInDate: moveInDate, moveOutDate: moveOutDate)
    }
}
