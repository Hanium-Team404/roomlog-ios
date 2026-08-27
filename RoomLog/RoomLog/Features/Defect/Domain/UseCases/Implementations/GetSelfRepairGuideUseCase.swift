//
//  GetSelfRepairGuideUseCase.swift
//  RoomLog
//
//  Created by wk1717 on 8/26/26.
//

import Foundation

final class GetSelfRepairGuideUseCase: GetSelfRepairGuideUseCaseProtocol {
    private let repository: DefectRepositoryProtocol

    init(repository: DefectRepositoryProtocol) {
        self.repository = repository
    }

    func execute(defectId: Int) async throws -> SelfRepairGuide {
        try await repository.getSelfRepairGuide(defectId: defectId)
    }
}
