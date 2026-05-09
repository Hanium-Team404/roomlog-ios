//
//  DeleteRoomUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol DeleteRoomUseCaseProtocol {
    func execute(roomId: Int) async throws
}
