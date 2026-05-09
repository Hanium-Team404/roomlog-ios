//
//  GetRoomDetailUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol GetRoomDetailUseCaseProtocol {
    func execute(roomId: Int) async throws -> RoomDetail
}
