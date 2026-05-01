//
//  GetUserUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation

final class GetUserUseCase: GetUserUseCaseProtocol {
    // MARK: - Property
    private let repository: MyPageRepositoryProtocol

    // MARK: - Init
    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function
    func execute() async throws -> User {
        try await repository.getUser()
    }
}
