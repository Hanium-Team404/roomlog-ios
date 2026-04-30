//
//  LoginUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: AuthRepositoryProtocol
    private let tokenStore: TokenStore

    init(
        repository: AuthRepositoryProtocol,
        tokenStore: TokenStore
    ) {
        self.repository = repository
        self.tokenStore = tokenStore
    }

    func execute(email: String, password: String) async throws -> AuthUser {
        let result = try await repository.login(body: LoginRequestDTO(email: email, password: password))
        
        try await tokenStore.save(
            accessToken: result.tokenPair.accessToken,
            refreshToken: result.tokenPair.refreshToken
        )
        
        return result
    }
}
