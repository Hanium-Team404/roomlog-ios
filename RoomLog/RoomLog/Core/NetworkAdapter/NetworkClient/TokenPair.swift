//
//  TokenPair.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

struct TokenPair: Sendable, Codable, Equatable {
    
    /// 기본 MainActor 격리에서 제외 — 불변 값이라 어느 격리 도메인에서 읽어도 안전하다
    nonisolated let accessToken: String
    
    nonisolated let refreshToken: String
    
    // MARK: - Initializer
    
    /// TokenPair 초기화
    nonisolated init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
