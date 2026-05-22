//
//  GetComparisonScansUseCaseProtocol.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

protocol GetComparisonScansUseCaseProtocol {
    func execute() async throws -> [ComparisonScan]
}
