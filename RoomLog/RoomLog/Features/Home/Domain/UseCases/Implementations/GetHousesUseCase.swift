//
//  GetHousesUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

final class GetHousesUseCase: GetHousesUseCaseProtocol {
    private let repository: HouseRepositoryProtocol

    init(repository: HouseRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> HouseList {
        try await repository.getHouses()
    }
}
