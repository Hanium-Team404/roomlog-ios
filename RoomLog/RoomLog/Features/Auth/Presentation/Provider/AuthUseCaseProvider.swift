//
//  AuthUseCaseProvider.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

protocol AuthUseCaseProvider {
    /// 로그인 UseCase
    var loginUseCase: LoginUseCaseProtocol { get }
    /// 회원가입 UseCase
    var signUpUseCase: SignUpUseCaseProtocol { get }
}

final class AuthUseCaseProviderImpl: AuthUseCaseProvider {
    // MARK: - Repository
    let loginUseCase: LoginUseCaseProtocol
    let signUpUseCase: SignUpUseCaseProtocol
    
    // MARK: - Init
    init(
        repositoryProvider: AuthRepositoryProtocol,
        tokenStore: TokenStore
    ) {
        self.loginUseCase = LoginUseCase(
            repository: repositoryProvider,
            tokenStore: tokenStore
        )
        
        self.signUpUseCase = SignUpUseCase(
            repository: repositoryProvider
        )
    }
}
