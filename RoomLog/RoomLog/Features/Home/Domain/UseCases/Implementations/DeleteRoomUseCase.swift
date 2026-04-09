//
//  DeleteRoomUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 4/9/26.
//

import Foundation

final class DeleteRoomUseCase: DeleteRoomUseCaseProtocol {
    // MARK: - Property
    private let repository: HomeRepositoryProtocol

    // MARK: - Init
    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function
    func execute(roomId: Int) async throws {
        try await repository.deleteRoom(roomId: roomId)
    }
}
