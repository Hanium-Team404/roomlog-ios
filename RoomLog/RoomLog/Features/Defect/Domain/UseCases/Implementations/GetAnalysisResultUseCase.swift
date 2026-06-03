//
//  GetAnalysisResultUseCase.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

final class GetAnalysisResultUseCase: GetAnalysisResultUseCaseProtocol {
    private let repository: DefectRepositoryProtocol

    init(repository: DefectRepositoryProtocol) {
        self.repository = repository
    }

    func execute(analysisId: Int) async throws -> AnalysisResult {
        try await repository.getAnalysisResult(analysisId: analysisId)
    }
}
