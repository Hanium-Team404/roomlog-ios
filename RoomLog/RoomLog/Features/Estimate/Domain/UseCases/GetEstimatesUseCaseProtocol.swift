//
//  GetEstimatesUseCaseProtocol.swift
//  RoomLog
//
//  Created by 송민교 on 5/17/26.
//

import Foundation

protocol GetEstimatesUseCaseProtocol {
    func execute() async throws -> [Estimate]
}
