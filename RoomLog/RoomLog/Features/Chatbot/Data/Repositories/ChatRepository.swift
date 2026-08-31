//
//  ChatRepository.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation
import Moya

final class ChatRepository: ChatRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func startSession() async throws -> ChatSession {
        let response = try await adapter.request(ChatTarget.startSession)
        let apiResponse: APIResponse<ChatSessionResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<ChatSessionResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().toDomain()
    }

    func sendMessage(sessionId: Int, message: String, guide: String?, defectId: Int?) async throws -> ChatAnswer {
        let response = try await adapter.request(
            ChatTarget.sendMessage(sessionId: sessionId, message: message, guide: guide, defectId: defectId)
        )
        let apiResponse: APIResponse<ChatAnswerResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<ChatAnswerResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().toDomain()
    }

    func getMessages(sessionId: Int) async throws -> [ChatMessage] {
        let response = try await adapter.request(ChatTarget.getMessages(sessionId: sessionId))
        let apiResponse: APIResponse<ChatHistoryResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<ChatHistoryResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().messages.map { $0.toDomain() }
    }

    func getMainHouseDefects() async throws -> [ChatSelectableDefect] {
        let response = try await adapter.request(ChatTarget.getMainHouseDefects)
        let apiResponse: APIResponse<MainHouseDefectsResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<MainHouseDefectsResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().defects.map { $0.toDomain() }
    }
}
