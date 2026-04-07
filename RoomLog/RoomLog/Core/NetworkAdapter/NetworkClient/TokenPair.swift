//
//  TokenPair.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

struct TokenPair: Sendable, Codable, Equatable {
    
    /// actor의 Isolation 규칙 무시 -> 불변 값이므로 동시에 여러 곳에서 참조 가능
    nonisolated let accessToken: String
    
    nonisolated let refreshToken: String
    
    // MARK: - Initializer
    
    /// TokenPair 초기화
    nonisolated init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
