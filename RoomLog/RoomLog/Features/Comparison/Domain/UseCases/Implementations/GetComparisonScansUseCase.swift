//
//  GetComparisonScansUseCase.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

final class GetComparisonScansUseCase: GetComparisonScansUseCaseProtocol {
    private let repository: ComparisonRepositoryProtocol

    init(repository: ComparisonRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [ComparisonScan] {
        try await repository.getScans()
    }
}
