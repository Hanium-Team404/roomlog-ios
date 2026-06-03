//
//  GetAnalysisResultUseCaseProtocol.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

protocol GetAnalysisResultUseCaseProtocol {
    func execute(analysisId: Int) async throws -> AnalysisResult
}
