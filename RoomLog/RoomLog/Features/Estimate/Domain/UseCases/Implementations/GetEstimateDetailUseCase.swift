//
//  GetEstimateDetailUseCase.swift
//  RoomLog
//
//  Created by minkyo on 5/28/26.
//

import Foundation

final class GetEstimateDetailUseCase: GetEstimateDetailUseCaseProtocol {
    private let repository: EstimateRepositoryProtocol

    init(repository: EstimateRepositoryProtocol) {
        self.repository = repository
    }

    func execute(estimateId: Int) async throws -> EstimateDetail {
        try await repository.getEstimateDetail(estimateId: estimateId)
    }
}
