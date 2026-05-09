//
//  UpdateRoomUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol UpdateRoomUseCaseProtocol {
    func execute(roomId: Int, name: String, address: String, moveInDate: Date, moveOutDate: Date?) async throws
}
