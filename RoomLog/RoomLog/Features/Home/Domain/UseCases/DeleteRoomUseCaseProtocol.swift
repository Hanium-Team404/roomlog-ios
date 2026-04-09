//
//  DeleteRoomUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/9/26.
//

import Foundation

/// 방 삭제 UseCaseProtocol
protocol DeleteRoomUseCaseProtocol {
    func execute(roomId: Int) async throws
}
