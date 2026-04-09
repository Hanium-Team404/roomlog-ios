//
//  FetchRoomDetailUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

/// 방 디테일 정보 조회 UseCaseProtocol
protocol FetchRoomDetailUseCaseProtocol {
    func execute(roomId: Int) async throws -> RoomDetail
}
