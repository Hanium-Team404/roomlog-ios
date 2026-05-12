//
//  UpdateUserUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

final class UpdateUserUseCase: UpdateUserUseCaseProtocol {

    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute(nickname: String) async throws {
        try await repository.updateUser(nickname: nickname)
    }
}
