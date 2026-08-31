//
//  StartChatSessionUseCaseProtocol.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

protocol StartChatSessionUseCaseProtocol {
    func execute() async throws -> ChatSession
}
