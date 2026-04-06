//
//  FetchRoomDetailUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

final class FetchRoomDetailUseCase: FetchRoomDetailUseCaseProtocol {
    // MARK: - Property
    private let repository: HomeRepositoryProtocol
    
    // MARK: - Init
    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    func execute(roomId: Int) async throws -> RoomDetail {
        try await repository.getRoomDetail(roomId: roomId)
    }
}
