//
//  SendChatMessageUseCase.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

final class SendChatMessageUseCase: SendChatMessageUseCaseProtocol {
    private let repository: ChatRepositoryProtocol

    init(repository: ChatRepositoryProtocol) {
        self.repository = repository
    }

    func execute(sessionId: Int, message: String, guide: String?, defectId: Int?) async throws -> ChatAnswer {
        try await repository.sendMessage(sessionId: sessionId, message: message, guide: guide, defectId: defectId)
    }
}
