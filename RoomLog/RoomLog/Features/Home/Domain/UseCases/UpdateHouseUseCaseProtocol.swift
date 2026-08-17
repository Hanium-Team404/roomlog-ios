//
//  UpdateHouseUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol UpdateHouseUseCaseProtocol {
    func execute(houseId: Int, name: String, address: String, houseColor: HouseColor, floorColor: FloorColor) async throws -> House
}
