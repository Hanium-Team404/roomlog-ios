//
//  GetHouseRoomsUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

final class GetHouseRoomsUseCase: GetHouseRoomsUseCaseProtocol {
    private let repository: HouseRepositoryProtocol

    init(repository: HouseRepositoryProtocol) {
        self.repository = repository
    }

    func execute(houseId: Int) async throws -> HouseRooms {
        try await repository.getHouseRooms(houseId: houseId)
    }
}
