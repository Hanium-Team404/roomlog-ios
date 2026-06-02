//
//  RequestAnalysisUseCase.swift
//  RoomLog
//
//  Created by minkyo on 5/26/26.
//

import Foundation

final class RequestAnalysisUseCase: RequestAnalysisUseCaseProtocol {
    private let repository: DefectRepositoryProtocol

    init(repository: DefectRepositoryProtocol) {
        self.repository = repository
    }

    func execute(inRoomId: Int, outRoomId: Int?) async throws -> (analysisId: Int, status: String) {
        try await repository.requestAnalysis(inRoomId: inRoomId, outRoomId: outRoomId)
    }
}
