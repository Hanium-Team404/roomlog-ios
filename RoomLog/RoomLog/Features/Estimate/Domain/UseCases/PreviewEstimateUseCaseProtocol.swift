//
//  PreviewEstimateUseCaseProtocol.swift
//  RoomLog
//
//  Created by minkyo on 5/28/26.
//

import Foundation

protocol PreviewEstimateUseCaseProtocol {
    func execute(message: String, analysisId: Int, providerExternalId: String) async throws -> EstimatePreview
}
