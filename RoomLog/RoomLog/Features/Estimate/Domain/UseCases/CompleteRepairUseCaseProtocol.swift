//
//  CompleteRepairUseCaseProtocol.swift
//  RoomLog
//
//  Created by 송민교 on 5/17/26.
//

import Foundation

protocol CompleteRepairUseCaseProtocol {
    func execute(estimateId: Int, repairCost: Int, note: String?) async throws
}
