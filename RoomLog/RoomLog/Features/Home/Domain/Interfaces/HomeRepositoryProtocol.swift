//
//  HomeRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

protocol HomeRepositoryProtocol {
    /// 메인 방 및 방 리스트 조회
    func getHomeData() async throws -> HomeData
    /// 선택한 방 정보 조회
    func getRoomDetail(roomId: Int) async throws -> RoomDetail
    /// 선택한 방 정보 업데이트
    func patchRoom(roomId: Int) async throws -> UpdatedRoomDetail
}
