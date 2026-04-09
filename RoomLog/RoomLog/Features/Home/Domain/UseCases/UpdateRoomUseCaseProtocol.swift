//
//  UpdateRoomUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

/// 방 상세 정보 업데이트 UseCaseProtocol
protocol UpdateRoomUseCaseProtocol {
    func execute(request: UpdatedRoomDetail) async throws -> UpdatedRoomDetail
}
