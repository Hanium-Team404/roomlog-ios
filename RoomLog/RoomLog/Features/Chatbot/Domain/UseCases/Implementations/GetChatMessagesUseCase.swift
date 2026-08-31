//
//  GetChatMessagesUseCase.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

final class GetChatMessagesUseCase: GetChatMessagesUseCaseProtocol {
    private let repository: ChatRepositoryProtocol

    init(repository: ChatRepositoryProtocol) {
        self.repository = repository
    }

    func execute(sessionId: Int) async throws -> [ChatMessage] {
        try await repository.getMessages(sessionId: sessionId)
    }
}
