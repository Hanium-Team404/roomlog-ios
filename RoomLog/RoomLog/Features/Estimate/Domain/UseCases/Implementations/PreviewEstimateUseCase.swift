//
//  PreviewEstimateUseCase.swift
//  RoomLog
//
//  Created by minkyo on 5/28/26.
//

import Foundation

final class PreviewEstimateUseCase: PreviewEstimateUseCaseProtocol {
    private let repository: EstimateRepositoryProtocol

    init(repository: EstimateRepositoryProtocol) {
        self.repository = repository
    }

    func execute(message: String, analysisId: Int, providerExternalId: String) async throws -> EstimatePreview {
        try await repository.previewEstimate(message: message, analysisId: analysisId, providerExternalId: providerExternalId)
    }
}
