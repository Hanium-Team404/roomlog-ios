//
//  SendChatMessageUseCaseProtocol.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

protocol SendChatMessageUseCaseProtocol {
    func execute(sessionId: Int, message: String, guide: String?, defectId: Int?) async throws -> ChatAnswer
}
