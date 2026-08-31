//
//  GetChatMessagesUseCaseProtocol.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

protocol GetChatMessagesUseCaseProtocol {
    func execute(sessionId: Int) async throws -> [ChatMessage]
}
