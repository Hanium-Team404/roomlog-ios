//
//  GetComparisonScansUseCase.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

final class GetComparisonHousesUseCase: GetComparisonHousesUseCaseProtocol {
    private let repository: ComparisonRepositoryProtocol

    init(repository: ComparisonRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [House] {
        try await repository.getHouses()
    }
}

final class GetComparisonRoomsUseCase: GetComparisonRoomsUseCaseProtocol {
    private let repository: ComparisonRepositoryProtocol

    init(repository: ComparisonRepositoryProtocol) {
        self.repository = repository
    }

    func execute(houseId: Int) async throws -> [ComparisonScan] {
        try await repository.getRooms(houseId: houseId)
    }
}
