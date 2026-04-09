//
//  SetMainRoomUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/9/26.
//

import Foundation

/// 대표 방 설정 UseCaseProtocol
protocol SetMainRoomUseCaseProtocol {
    func execute(roomId: Int) async throws
}
