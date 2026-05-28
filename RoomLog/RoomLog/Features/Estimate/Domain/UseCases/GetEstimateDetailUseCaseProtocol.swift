//
//  GetEstimateDetailUseCaseProtocol.swift
//  RoomLog
//
//  Created by minkyo on 5/28/26.
//

import Foundation

protocol GetEstimateDetailUseCaseProtocol {
    func execute(estimateId: Int) async throws -> EstimateDetail
}
