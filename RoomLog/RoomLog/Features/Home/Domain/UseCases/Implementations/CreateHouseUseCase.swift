//
//  CreateHouseUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

final class CreateHouseUseCase: CreateHouseUseCaseProtocol {
    private let repository: HouseRepositoryProtocol

    init(repository: HouseRepositoryProtocol) {
        self.repository = repository
    }

    func execute(name: String, address: String, houseColor: HouseColor, floorColor: FloorColor) async throws -> House {
        try await repository.createHouse(name: name, address: address, houseColor: houseColor, floorColor: floorColor)
    }
}
