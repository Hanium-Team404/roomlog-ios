//
//  LoginUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    func execute(email: String, password: String) async throws -> AuthUser {
        try await repository.login(email: email, password: password)
    }
}
