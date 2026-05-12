//
//  DeleteUserUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

final class DeleteUserUseCase: DeleteUserUseCaseProtocol {

    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.deleteUser()
    }
}
