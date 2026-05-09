//
//  RoomTarget.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation
import Moya
internal import Alamofire

enum RoomTarget {
    case getRoomDetail(roomId: Int)
    case updateRoom(roomId: Int, request: UpdateRoomRequestDTO)
    case deleteRoom(roomId: Int)
}

extension RoomTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getRoomDetail(let roomId),
             .updateRoom(let roomId, _),
             .deleteRoom(let roomId):
            return "/rooms/\(roomId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getRoomDetail:
            return .get
        case .updateRoom:
            return .patch
        case .deleteRoom:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case .getRoomDetail, .deleteRoom:
            return .requestPlain
        case .updateRoom(_, let request):
            return .requestJSONEncodable(request)
        }
    }
}
