//
//  RoomTarget.swift
//  RoomLog
//
//  Created by 김도연 on 4/9/26.
//

import Foundation
import Moya
internal import Alamofire

enum RoomTarget {
    case getHomeData
    case getRoomDetail(roomId: Int)
    case patchRoom(roomId: Int, request: PatchRoomRequestDTO)
    case deleteRoom(roomId: Int)
    case patchMainRoom(roomId: Int)
}

extension RoomTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getHomeData:
            return "/rooms"
        case .getRoomDetail(let roomId):
            return "/rooms/\(roomId)"
        case .patchRoom(let roomId, _):
            return "/rooms/\(roomId)"
        case .deleteRoom(let roomId):
            return "/rooms/\(roomId)"
        case .patchMainRoom(let roomId):
            return "/rooms/\(roomId)/main"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getHomeData, .getRoomDetail:
            return .get
        case .patchRoom, .patchMainRoom:
            return .patch
        case .deleteRoom:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case .getHomeData, .getRoomDetail, .deleteRoom, .patchMainRoom:
            return .requestPlain
        case .patchRoom(_, let request):
            return .requestJSONEncodable(request)
        }
    }
}
