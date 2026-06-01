//
//  MockMyPageRepository.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
@testable import RoomLog

final class MockMyPageRepository: MyPageRepositoryProtocol {

    // MARK: - Call Tracking

    var getUserCallCount = 0
    var updateUserCallCount = 0
    var deleteUserCallCount = 0

    // MARK: - Captured Arguments

    var lastUpdatedNickname: String?

    // MARK: - Stub Results

    var getUserResult: Result<User, Error> = .success(
        User(id: 1, nickname: "테스트유저", email: "test@test.com", createdAt: Date())
    )
    var updateUserResult: Result<Void, Error> = .success(())
    var deleteUserResult: Result<Void, Error> = .success(())

    // MARK: - MyPageRepositoryProtocol

    func getUser() async throws -> User {
        getUserCallCount += 1
        return try getUserResult.get()
    }

    func updateUser(nickname: String) async throws {
        updateUserCallCount += 1
        lastUpdatedNickname = nickname
        try updateUserResult.get()
    }

    func deleteUser() async throws {
        deleteUserCallCount += 1
        try deleteUserResult.get()
    }
}
