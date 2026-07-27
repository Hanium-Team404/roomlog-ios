//
//  HouseRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol HouseRepositoryProtocol {
    /// 집 목록 조회
    func getHouses() async throws -> HouseList
    /// 집 생성
    func createHouse(name: String, address: String?) async throws -> House
    /// 집 수정
    func updateHouse(houseId: Int, name: String, address: String?) async throws -> House
    /// 집 삭제
    func deleteHouse(houseId: Int) async throws
    /// 대표 집 설정
    func setMainHouse(houseId: Int) async throws
    /// 집의 방 목록 조회
    func getHouseRooms(houseId: Int) async throws -> HouseRooms
    /// 집에 방 생성. 생성된 방의 roomId 반환.
    func createRoom(houseId: Int, name: String, scanId: Int) async throws -> Int
}
