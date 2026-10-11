//
//  MockChatbotUseCaseProvider.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/11/26.
//

import Foundation
@testable import RoomLog

final class MockChatbotUseCaseProvider: ChatbotUseCaseProvider {

    // MARK: - Call Tracking

    /// 마지막 메시지 전송 요청 인자 (defectId 전달 여부 검증용)
    var lastSendRequest: (message: String, guide: String?, defectId: Int?)?

    // MARK: - Stub Results

    var startSessionResult: Result<ChatSession, Error> = .success(
        ChatSession(id: 1, greeting: "안녕하세요", suggestedQuestions: [])
    )
    var sendMessageResult: Result<ChatAnswer, Error> = .success(
        ChatAnswer(messageId: 1, answer: "답변", source: .gpt, suggestedQuestions: nil)
    )
    var getMessagesResult: Result<[ChatMessage], Error> = .success([])
    var getSelectableDefectsResult: Result<[ChatSelectableDefect], Error> = .success([])

    // MARK: - ChatbotUseCaseProvider

    func makeStartChatSessionUseCase() -> StartChatSessionUseCaseProtocol {
        StubStartChatSessionUseCase(result: startSessionResult)
    }
    func makeSendChatMessageUseCase() -> SendChatMessageUseCaseProtocol {
        StubSendChatMessageUseCase(result: sendMessageResult, onExecute: { self.lastSendRequest = $0 })
    }
    func makeGetChatMessagesUseCase() -> GetChatMessagesUseCaseProtocol {
        StubGetChatMessagesUseCase(result: getMessagesResult)
    }
    func makeGetChatSelectableDefectsUseCase() -> GetChatSelectableDefectsUseCaseProtocol {
        StubGetChatSelectableDefectsUseCase(result: getSelectableDefectsResult)
    }
}

// MARK: - Stub UseCases

private struct StubStartChatSessionUseCase: StartChatSessionUseCaseProtocol {
    let result: Result<ChatSession, Error>
    func execute() async throws -> ChatSession { try result.get() }
}

private struct StubSendChatMessageUseCase: SendChatMessageUseCaseProtocol {
    let result: Result<ChatAnswer, Error>
    let onExecute: ((message: String, guide: String?, defectId: Int?)) -> Void
    func execute(sessionId: Int, message: String, guide: String?, defectId: Int?) async throws -> ChatAnswer {
        onExecute((message, guide, defectId))
        return try result.get()
    }
}

private struct StubGetChatMessagesUseCase: GetChatMessagesUseCaseProtocol {
    let result: Result<[ChatMessage], Error>
    func execute(sessionId: Int) async throws -> [ChatMessage] { try result.get() }
}

private struct StubGetChatSelectableDefectsUseCase: GetChatSelectableDefectsUseCaseProtocol {
    let result: Result<[ChatSelectableDefect], Error>
    func execute() async throws -> [ChatSelectableDefect] { try result.get() }
}
