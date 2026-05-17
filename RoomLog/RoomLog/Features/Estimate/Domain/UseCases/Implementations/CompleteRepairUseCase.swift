//
//  CompleteRepairUseCase.swift
//  RoomLog
//
//  Created by 송민교 on 5/17/26.
//

import Foundation

final class CompleteRepairUseCase: CompleteRepairUseCaseProtocol {
    private let repository: EstimateRepositoryProtocol

    init(repository: EstimateRepositoryProtocol) {
        self.repository = repository
    }

    func execute(estimateId: Int) async throws {
        try await repository.completeRepair(estimateId: estimateId)
    }
}
