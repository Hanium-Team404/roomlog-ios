//
//  AuthUseCaseProvider.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

protocol AuthUseCaseProvider {
    func makeLoginUseCase() -> LoginUseCaseProtocol
    func makeSignUpUseCase() -> SignUpUseCaseProtocol
}

final class AuthUseCaseProviderImpl: AuthUseCaseProvider {
    // MARK: - Repository
    private let authRepository: AuthRepositoryProtocol

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter, tokenStore: TokenStore) {
        self.authRepository = AuthRepository(adapter: adapter, tokenStore: tokenStore)
    }

    // MARK: - Auth UseCases
    func makeLoginUseCase() -> LoginUseCaseProtocol {
        LoginUseCase(repository: authRepository)
    }

    func makeSignUpUseCase() -> SignUpUseCaseProtocol {
        SignUpUseCase(repository: authRepository)
    }
}
