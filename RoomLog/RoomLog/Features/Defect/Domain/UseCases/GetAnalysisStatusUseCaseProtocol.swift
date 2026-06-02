//
//  GetAnalysisStatusUseCaseProtocol.swift
//  RoomLog
//
//  Created by minkyo on 5/26/26.
//

import Foundation

protocol GetAnalysisStatusUseCaseProtocol {
    func execute(analysisId: Int) async throws -> String
}
