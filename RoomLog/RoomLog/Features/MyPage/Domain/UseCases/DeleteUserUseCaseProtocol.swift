//
//  DeleteUserUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

/// 회원 탈퇴 UseCase
protocol DeleteUserUseCaseProtocol {
    func execute() async throws
}
