//
//  SignUpUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

final class SignUpUseCase: SignUpUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    func execute(email: String, password: String, nickname: String) async throws -> SignedUpUser {
        try await repository.signUp(body: SignUpRequestDTO(email: email, password: password, nickname: nickname))
    }
}
