//
//  GetComparisonHistoriesUseCase.swift
//  RoomLog
//
//  Created by minkyo on 6/4/26.
//

import Foundation

final class GetComparisonHistoriesUseCase: GetComparisonHistoriesUseCaseProtocol {
    private let repository: ComparisonRepositoryProtocol

    init(repository: ComparisonRepositoryProtocol) {
        self.repository = repository
    }

    func execute(houseId: Int) async throws -> [ComparisonHistory] {
        try await repository.getComparisonHistories(houseId: houseId)
    }
}
