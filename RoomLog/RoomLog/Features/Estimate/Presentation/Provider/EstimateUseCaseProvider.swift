//
//  EstimateUseCaseProvider.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

protocol EstimateUseCaseProvider {
    func makeGetRepairShopsUseCase() -> GetRepairShopsUseCaseProtocol
    func makeGetRepairShopsByRoomUseCase() -> GetRepairShopsByRoomUseCaseProtocol
    func makeCreateEstimateUseCase() -> CreateEstimateUseCaseProtocol
}

final class EstimateUseCaseProviderImpl: EstimateUseCaseProvider {
    private let repository: EstimateRepositoryProtocol

    init(adapter: MoyaNetworkAdapter) {
        self.repository = EstimateRepository(adapter: adapter)
    }

    func makeGetRepairShopsUseCase() -> GetRepairShopsUseCaseProtocol {
        GetRepairShopsUseCase(repository: repository)
    }

    func makeGetRepairShopsByRoomUseCase() -> GetRepairShopsByRoomUseCaseProtocol {
        GetRepairShopsByRoomUseCase(repository: repository)
    }

    func makeCreateEstimateUseCase() -> CreateEstimateUseCaseProtocol {
        CreateEstimateUseCase(repository: repository)
    }
}
