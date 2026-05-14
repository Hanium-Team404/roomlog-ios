//
//  CreateEstimateUseCaseProtocol.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

protocol CreateEstimateUseCaseProtocol {
    func execute(message: String, roomId: Int, analysisId: Int?, defectIds: [Int], provider: RepairShop) async throws
}
