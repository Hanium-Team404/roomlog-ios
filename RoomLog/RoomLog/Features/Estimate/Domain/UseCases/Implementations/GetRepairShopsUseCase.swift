//
//  GetRepairShopsUseCase.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

final class GetRepairShopsUseCase: GetRepairShopsUseCaseProtocol {
    private let repository: EstimateRepositoryProtocol

    init(repository: EstimateRepositoryProtocol) {
        self.repository = repository
    }

    func execute(analysisId: Int, type: String? = nil, radius: String? = nil, sort: String? = nil) async throws -> [RepairShop] {
        try await repository.getRepairShops(analysisId: analysisId, type: type, radius: radius, sort: sort)
    }
}
