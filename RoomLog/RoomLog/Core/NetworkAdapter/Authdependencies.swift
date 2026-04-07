//
//  Authdependencies.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation
import Moya

/// 인증 관련 의존성을 조립해주는 팩토리
enum AuthSystemFactory {
    
    /// 실제 앱에서 사용할 NetworkClient를 생성합니다.
    static func makeNetworkClient(
        baseURL: URL,
        session: URLSession = .shared,
        tokenStore: TokenStore? = nil
    ) -> NetworkClient {
        // 1. 토큰 갱신 서비스 생성
        let store = tokenStore ?? KeychainTokenStore()
        
        let refreshService = TokenRefreshServiceImpl(baseURL: baseURL, session: session)
        
        // 2. NetworkClient 조립 후 반환
        return NetworkClient(
            session: session,
            tokenStore: store,
            refreshService: refreshService
        )
    }
}
