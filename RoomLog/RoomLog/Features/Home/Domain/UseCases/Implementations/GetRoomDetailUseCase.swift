//
//  GetRoomDetailUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

final class GetRoomDetailUseCase: GetRoomDetailUseCaseProtocol {
    private let repository: RoomRepositoryProtocol

    init(repository: RoomRepositoryProtocol) {
        self.repository = repository
    }

    func execute(roomId: Int) async throws -> RoomDetail {
        try await repository.getRoomDetail(roomId: roomId)
    }
}
