//
//  ComparisonUseCaseProvider.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

protocol ComparisonUseCaseProvider {
    func makeGetComparisonHousesUseCase() -> GetComparisonHousesUseCaseProtocol
    func makeGetComparisonRoomsUseCase() -> GetComparisonRoomsUseCaseProtocol
    func makeGetComparisonHistoriesUseCase() -> GetComparisonHistoriesUseCaseProtocol
}

final class ComparisonUseCaseProviderImpl: ComparisonUseCaseProvider {
    private let repository: ComparisonRepositoryProtocol

    init(repository: ComparisonRepositoryProtocol) {
        self.repository = repository
    }

    init(adapter: MoyaNetworkAdapter) {
        self.repository = ComparisonRepository(adapter: adapter)
    }

    func makeGetComparisonHousesUseCase() -> GetComparisonHousesUseCaseProtocol {
        GetComparisonHousesUseCase(repository: repository)
    }

    func makeGetComparisonRoomsUseCase() -> GetComparisonRoomsUseCaseProtocol {
        GetComparisonRoomsUseCase(repository: repository)
    }

    func makeGetComparisonHistoriesUseCase() -> GetComparisonHistoriesUseCaseProtocol {
        GetComparisonHistoriesUseCase(repository: repository)
    }
}
