//
//  GetUserUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation

/// 유저 정보 조회 UseCase
protocol GetUserUseCaseProtocol {
    func execute() async throws -> User
}
