//
//  DeleteHouseUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

final class DeleteHouseUseCase: DeleteHouseUseCaseProtocol {
    private let repository: HouseRepositoryProtocol

    init(repository: HouseRepositoryProtocol) {
        self.repository = repository
    }

    func execute(houseId: Int) async throws {
        try await repository.deleteHouse(houseId: houseId)
    }
}
