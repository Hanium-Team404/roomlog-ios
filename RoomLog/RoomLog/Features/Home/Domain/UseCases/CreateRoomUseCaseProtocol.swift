//
//  CreateRoomUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol CreateRoomUseCaseProtocol {
    /// 생성된 방의 roomId 반환.
    func execute(houseId: Int, name: String, scanId: Int) async throws -> Int
}
