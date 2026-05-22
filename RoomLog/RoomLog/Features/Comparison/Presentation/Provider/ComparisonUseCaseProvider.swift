//
//  ComparisonUseCaseProvider.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

protocol ComparisonUseCaseProvider {
    func makeGetComparisonScansUseCase() -> GetComparisonScansUseCaseProtocol
}

final class ComparisonUseCaseProviderImpl: ComparisonUseCaseProvider {
    private let repository: ComparisonRepositoryProtocol

    init(repository: ComparisonRepositoryProtocol) {
        self.repository = repository
    }

    func makeGetComparisonScansUseCase() -> GetComparisonScansUseCaseProtocol {
        GetComparisonScansUseCase(repository: repository)
    }
}
