//
//  DefaultAuthenticationPolicy.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

struct DefaultAuthenticationPolicy: AuthenticationPolicy, Sendable {
    
    // MARK: - Initializer
    nonisolated init() {}
    
    // MARK: - AuthenticationPolicy
    

    ///
    /// - Parameter request: 판단할 URLRequest
    /// - Returns: 항상  `true`
    ///   -> 모든 API 요청에 인증 적용
    nonisolated func requireAuthentication(_ request: URLRequest) -> Bool {
        true
    }
    
    /// 401 Unautherized 응답을 인증 실패로 판단
    /// `true` 반환 시 NerworkClient가 자동으로 토큰 갱신
    ///
    /// - Parameter response: 판단할 HTTPURLResponse
    ///
    /// - Returns:
    ///   - `true` : 상태 코드가 401일 때
    ///   - `false` : 401이외의 모든 상태 코드
    nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 401
    }
}
