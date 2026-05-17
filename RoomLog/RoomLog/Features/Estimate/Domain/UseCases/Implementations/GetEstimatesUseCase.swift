//
//  GetEstimatesUseCase.swift
//  RoomLog
//
//  Created by 송민교 on 5/17/26.
//

import Foundation

final class GetEstimatesUseCase: GetEstimatesUseCaseProtocol {
    private let repository: EstimateRepositoryProtocol

    init(repository: EstimateRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Estimate] {
        try await repository.getEstimates()
    }
}
