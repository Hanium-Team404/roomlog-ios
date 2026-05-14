//
//  MyPageUseCaseProvider.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation

protocol MyPageUseCaseProvider {
    func makeGetUserUseCase() -> GetUserUseCaseProtocol
    func makeUpdateUserUseCase() -> UpdateUserUseCaseProtocol
    func makeDeleteUserUseCase() -> DeleteUserUseCaseProtocol
}

final class MyPageUseCaseProviderImpl: MyPageUseCaseProvider {
    // MARK: - Repository
    private let myPageRepository: MyPageRepositoryProtocol

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter) {
        self.myPageRepository = MyPageRepository(adapter: adapter)
    }

    // MARK: - MyPage UseCases
    func makeGetUserUseCase() -> GetUserUseCaseProtocol {
        GetUserUseCase(repository: myPageRepository)
    }

    func makeUpdateUserUseCase() -> UpdateUserUseCaseProtocol {
        UpdateUserUseCase(repository: myPageRepository)
    }

    func makeDeleteUserUseCase() -> DeleteUserUseCaseProtocol {
        DeleteUserUseCase(repository: myPageRepository)
    }
}
