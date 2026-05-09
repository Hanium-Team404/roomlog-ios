//
//  GetHouseRoomsUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol GetHouseRoomsUseCaseProtocol {
    func execute(houseId: Int) async throws -> HouseRooms
}
