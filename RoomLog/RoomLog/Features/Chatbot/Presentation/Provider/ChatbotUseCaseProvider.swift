//
//  ChatbotUseCaseProvider.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

protocol ChatbotUseCaseProvider {
    func makeStartChatSessionUseCase() -> StartChatSessionUseCaseProtocol
    func makeSendChatMessageUseCase() -> SendChatMessageUseCaseProtocol
    func makeGetChatMessagesUseCase() -> GetChatMessagesUseCaseProtocol
    func makeGetChatSelectableDefectsUseCase() -> GetChatSelectableDefectsUseCaseProtocol
}

final class ChatbotUseCaseProviderImpl: ChatbotUseCaseProvider {
    // MARK: - Repository
    private let chatRepository: ChatRepositoryProtocol

    // MARK: - Init
    init(chatRepository: ChatRepositoryProtocol) {
        self.chatRepository = chatRepository
    }

    // MARK: - Chatbot UseCases
    func makeStartChatSessionUseCase() -> StartChatSessionUseCaseProtocol {
        StartChatSessionUseCase(repository: chatRepository)
    }

    func makeSendChatMessageUseCase() -> SendChatMessageUseCaseProtocol {
        SendChatMessageUseCase(repository: chatRepository)
    }

    func makeGetChatMessagesUseCase() -> GetChatMessagesUseCaseProtocol {
        GetChatMessagesUseCase(repository: chatRepository)
    }

    func makeGetChatSelectableDefectsUseCase() -> GetChatSelectableDefectsUseCaseProtocol {
        GetChatSelectableDefectsUseCase(repository: chatRepository)
    }
}
