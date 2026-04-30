//
//  AuthRepositoryProvider.swift
//  RoomLog
//
//  Created by 김도연 on 5/1/26.
//

import Foundation

protocol AuthRepositoryProvider {
    
    var authRepository: AuthRepositoryProtocol { get }
    
}

final class AuthRepositoryProviderImpl: AuthRepositoryProvider {
    
    let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    /// 실제 서버 연결 Provider 생성
    func real(
        adapter: MoyaNetworkAdapter
    ) -> AuthRepositoryProvider {
        AuthRepositoryProviderImpl(
            authRepository: AuthRepository(adapter: adapter)
        )
    }
}
