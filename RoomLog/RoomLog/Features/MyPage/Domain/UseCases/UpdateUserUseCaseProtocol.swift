//
//  UpdateUserUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

/// 닉네임 수정 UseCase
protocol UpdateUserUseCaseProtocol {
    func execute(nickname: String) async throws
}
