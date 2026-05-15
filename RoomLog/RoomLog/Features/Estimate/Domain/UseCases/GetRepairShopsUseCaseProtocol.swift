//
//  GetRepairShopsUseCaseProtocol.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

protocol GetRepairShopsUseCaseProtocol {
    func execute(analysisId: Int, type: String?, radius: String?, sort: String?) async throws -> [RepairShop]
}
