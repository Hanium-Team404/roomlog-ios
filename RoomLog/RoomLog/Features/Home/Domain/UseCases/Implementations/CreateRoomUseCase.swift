//
//  CreateRoomUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

final class CreateRoomUseCase: CreateRoomUseCaseProtocol {
    private let repository: HouseRepositoryProtocol

    init(repository: HouseRepositoryProtocol) {
        self.repository = repository
    }

    func execute(houseId: Int, name: String, scanId: Int) async throws {
        try await repository.createRoom(houseId: houseId, name: name, scanId: scanId)
    }
}
