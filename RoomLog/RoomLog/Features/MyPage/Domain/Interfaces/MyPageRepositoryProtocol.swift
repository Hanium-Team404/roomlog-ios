//
//  MyPageRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation

protocol MyPageRepositoryProtocol {
    /// 유저 정보 조회
    func getUser() async throws -> User
    /// 닉네임 수정
    func updateUser(nickname: String) async throws
    /// 회원 탈퇴
    func deleteUser() async throws
}
