//
//  FetchHomeDataUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

final class FetchHomeDataUseCase: FetchHomeDataUseCaseProtocol {
    // MARK: - Property
    private let repository: HomeRepositoryProtocol
    
    // MARK: - Init
    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    func execute() async throws -> HomeData {
        try await repository.getHomeData()
    }
}
