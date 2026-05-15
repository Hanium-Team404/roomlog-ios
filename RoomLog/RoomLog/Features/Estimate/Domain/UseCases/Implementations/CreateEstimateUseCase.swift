//
//  CreateEstimateUseCase.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

final class CreateEstimateUseCase: CreateEstimateUseCaseProtocol {
    private let repository: EstimateRepositoryProtocol

    init(repository: EstimateRepositoryProtocol) {
        self.repository = repository
    }

    func execute(message: String, roomId: Int, analysisId: Int?, defectIds: [Int], provider: RepairShop) async throws {
        try await repository.createEstimate(
            message: message,
            roomId: roomId,
            analysisId: analysisId,
            defectIds: defectIds,
            provider: provider
        )
    }
}
