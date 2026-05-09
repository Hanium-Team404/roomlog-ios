//
//  UpdateHouseUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

final class UpdateHouseUseCase: UpdateHouseUseCaseProtocol {
    private let repository: HouseRepositoryProtocol

    init(repository: HouseRepositoryProtocol) {
        self.repository = repository
    }

    func execute(houseId: Int, name: String) async throws -> House {
        try await repository.updateHouse(houseId: houseId, name: name)
    }
}
