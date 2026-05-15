//
//  RoomRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol RoomRepositoryProtocol {
    /// 방 상세 조회
    func getRoomDetail(roomId: Int) async throws -> RoomDetail
    /// 방 정보 수정
    func updateRoom(roomId: Int, name: String, moveInDate: Date, moveOutDate: Date?) async throws
    /// 방 삭제
    func deleteRoom(roomId: Int) async throws
}
