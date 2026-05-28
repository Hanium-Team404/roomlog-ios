//
//  RequestAnalysisUseCaseProtocol.swift
//  RoomLog
//
//  Created by minkyo on 5/26/26.
//

import Foundation

protocol RequestAnalysisUseCaseProtocol {
    func execute(inRoomId: Int, outRoomId: Int?) async throws -> (analysisId: Int, status: String)
}
