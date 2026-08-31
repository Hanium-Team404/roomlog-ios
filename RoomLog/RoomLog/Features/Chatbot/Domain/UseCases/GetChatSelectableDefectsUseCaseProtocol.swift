//
//  GetChatSelectableDefectsUseCaseProtocol.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

protocol GetChatSelectableDefectsUseCaseProtocol {
    func execute() async throws -> [ChatSelectableDefect]
}
