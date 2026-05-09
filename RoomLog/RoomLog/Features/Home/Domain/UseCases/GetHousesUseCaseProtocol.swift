//
//  GetHousesUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation

protocol GetHousesUseCaseProtocol {
    func execute() async throws -> HouseList
}
