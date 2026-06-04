//
//  GetComparisonHistoriesUseCaseProtocol.swift
//  RoomLog
//
//  Created by minkyo on 6/4/26.
//

import Foundation

protocol GetComparisonHistoriesUseCaseProtocol {
    func execute(houseId: Int) async throws -> [ComparisonHistory]
}
