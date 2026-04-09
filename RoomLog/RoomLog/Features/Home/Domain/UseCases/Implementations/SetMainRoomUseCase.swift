//
//  SetMainRoomUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 4/9/26.
//

import Foundation

final class SetMainRoomUseCase: SetMainRoomUseCaseProtocol {
    // MARK: - Property
    private let repository: HomeRepositoryProtocol

    // MARK: - Init
    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function
    func execute(roomId: Int) async throws {
        try await repository.setMainRoom(roomId: roomId)
    }
}
