//
//  EstimateRepositoryProtocol.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

protocol EstimateRepositoryProtocol {
    func getRepairShops(analysisId: Int, type: String?, radius: String?, sort: String?) async throws -> [RepairShop]
    func getRepairShopsByRoom(roomId: Int, type: String?, radius: String?, sort: String?) async throws -> (shops: [RepairShop], analysisId: Int?)
    func createEstimate(message: String, roomId: Int, analysisId: Int?, defectIds: [Int], provider: RepairShop) async throws
}
