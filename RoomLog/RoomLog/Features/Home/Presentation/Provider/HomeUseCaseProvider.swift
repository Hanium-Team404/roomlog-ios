//
//  HomeUseCaseProvider.swift
//  RoomLog
//
//  Created by 김도연 on 4/14/26.
//

import Foundation

protocol HomeUseCaseProvider {
    func makeFetchHomeDataUseCase() -> FetchHomeDataUseCaseProtocol
    func makeFetchRoomDetailUseCase() -> FetchRoomDetailUseCaseProtocol
    func makeUpdateRoomUseCase() -> UpdateRoomUseCaseProtocol
    func makePatchMainRoomUseCase() -> PatchMainRoomUseCaseProtocol
    func makeDeleteRoomUseCase() -> DeleteRoomUseCaseProtocol
}

final class HomeUseCaseProviderImpl: HomeUseCaseProvider {
    // MARK: - Repository
    private let homeRepository: HomeRepositoryProtocol

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter) {
        self.homeRepository = HomeRepository(adapter: adapter)
    }

    // MARK: - Home UseCases
    func makeFetchHomeDataUseCase() -> FetchHomeDataUseCaseProtocol {
        FetchHomeDataUseCase(repository: homeRepository)
    }

    func makeFetchRoomDetailUseCase() -> FetchRoomDetailUseCaseProtocol {
        FetchRoomDetailUseCase(repository: homeRepository)
    }

    func makeUpdateRoomUseCase() -> UpdateRoomUseCaseProtocol {
        UpdateRoomUseCase(repository: homeRepository)
    }

    func makePatchMainRoomUseCase() -> PatchMainRoomUseCaseProtocol {
        PatchMainRoomUseCase(repository: homeRepository)
    }

    func makeDeleteRoomUseCase() -> DeleteRoomUseCaseProtocol {
        DeleteRoomUseCase(repository: homeRepository)
    }
}
