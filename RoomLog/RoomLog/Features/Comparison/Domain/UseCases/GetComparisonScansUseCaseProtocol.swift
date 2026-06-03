//
//  GetComparisonScansUseCaseProtocol.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

protocol GetComparisonHousesUseCaseProtocol {
    func execute() async throws -> [House]
}

protocol GetComparisonRoomsUseCaseProtocol {
    func execute(houseId: Int) async throws -> [ComparisonScan]
}
