//
//  CheckSessionUseCaseProtocol.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/9/26.
//

import Foundation

/// 저장된 토큰으로 현재 세션의 사용자를 확인하는 UseCase.
/// Splash가 다른 Feature의 유저 모델을 알지 않도록 사용자 ID만 돌려준다
protocol CheckSessionUseCaseProtocol {
    /// 세션이 유효하면 사용자 ID를 돌려주고, 아니면 던진다
    func execute() async throws -> Int
}
