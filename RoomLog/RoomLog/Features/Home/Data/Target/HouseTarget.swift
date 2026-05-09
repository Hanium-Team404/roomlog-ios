//
//  HouseTarget.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation
import Moya
internal import Alamofire

enum HouseTarget {
    case getHouses
    case createHouse(request: CreateHouseRequestDTO)
    case updateHouse(houseId: Int, request: UpdateHouseRequestDTO)
    case deleteHouse(houseId: Int)
    case setMainHouse(houseId: Int)
    case getHouseRooms(houseId: Int)
    case createRoom(houseId: Int, request: CreateRoomRequestDTO)
}

extension HouseTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getHouses, .createHouse:
            return "/houses"
        case .updateHouse(let houseId, _), .deleteHouse(let houseId):
            return "/houses/\(houseId)"
        case .setMainHouse(let houseId):
            return "/houses/\(houseId)/main"
        case .getHouseRooms(let houseId), .createRoom(let houseId, _):
            return "/houses/\(houseId)/rooms"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getHouses, .getHouseRooms:
            return .get
        case .createHouse, .createRoom:
            return .post
        case .updateHouse, .setMainHouse:
            return .patch
        case .deleteHouse:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case .getHouses, .deleteHouse, .setMainHouse, .getHouseRooms:
            return .requestPlain
        case .createHouse(let request):
            return .requestJSONEncodable(request)
        case .updateHouse(_, let request):
            return .requestJSONEncodable(request)
        case .createRoom(_, let request):
            return .requestJSONEncodable(request)
        }
    }
}
