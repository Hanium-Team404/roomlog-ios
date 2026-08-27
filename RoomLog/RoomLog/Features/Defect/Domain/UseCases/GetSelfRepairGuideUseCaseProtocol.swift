//
//  GetSelfRepairGuideUseCaseProtocol.swift
//  RoomLog
//
//  Created by wk1717 on 8/26/26.
//

import Foundation

protocol GetSelfRepairGuideUseCaseProtocol {
    func execute(defectId: Int) async throws -> SelfRepairGuide
}
