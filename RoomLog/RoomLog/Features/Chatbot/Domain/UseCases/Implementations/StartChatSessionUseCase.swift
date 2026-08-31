//
//  StartChatSessionUseCase.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

final class StartChatSessionUseCase: StartChatSessionUseCaseProtocol {
    private let repository: ChatRepositoryProtocol

    init(repository: ChatRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> ChatSession {
        try await repository.startSession()
    }
}
