//
//  MockMyPageUseCaseProvider.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
@testable import RoomLog

final class MockMyPageUseCaseProvider: MyPageUseCaseProvider {

    // MARK: - Call Tracking

    var updateUserCallCount = 0

    // MARK: - Stub Results

    var getUserResult: Result<User, Error> = .success(
        User(id: 1, nickname: "테스트유저", email: "test@test.com", createdAt: Date())
    )
    var updateUserResult: Result<Void, Error> = .success(())
    var deleteUserResult: Result<Void, Error> = .success(())

    // MARK: - MyPageUseCaseProvider

    func makeGetUserUseCase() -> GetUserUseCaseProtocol {
        StubGetUserUseCase(result: getUserResult)
    }
    func makeUpdateUserUseCase() -> UpdateUserUseCaseProtocol {
        StubUpdateUserUseCase(result: updateUserResult, onExecute: { self.updateUserCallCount += 1 })
    }
    func makeDeleteUserUseCase() -> DeleteUserUseCaseProtocol {
        StubDeleteUserUseCase(result: deleteUserResult)
    }
}

// MARK: - Stub UseCases

private struct StubGetUserUseCase: GetUserUseCaseProtocol {
    let result: Result<User, Error>
    func execute() async throws -> User { try result.get() }
}

private struct StubUpdateUserUseCase: UpdateUserUseCaseProtocol {
    let result: Result<Void, Error>
    let onExecute: () -> Void
    func execute(nickname: String) async throws {
        onExecute()
        try result.get()
    }
}

private struct StubDeleteUserUseCase: DeleteUserUseCaseProtocol {
    let result: Result<Void, Error>
    func execute() async throws { try result.get() }
}
