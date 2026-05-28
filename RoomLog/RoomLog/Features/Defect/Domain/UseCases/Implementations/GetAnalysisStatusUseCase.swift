//
//  GetAnalysisStatusUseCase.swift
//  RoomLog
//
//  Created by minkyo on 5/26/26.
//

import Foundation

final class GetAnalysisStatusUseCase: GetAnalysisStatusUseCaseProtocol {
    private let repository: DefectRepositoryProtocol

    init(repository: DefectRepositoryProtocol) {
        self.repository = repository
    }

    func execute(analysisId: Int) async throws -> String {
        try await repository.getAnalysisStatus(analysisId: analysisId)
    }
}
