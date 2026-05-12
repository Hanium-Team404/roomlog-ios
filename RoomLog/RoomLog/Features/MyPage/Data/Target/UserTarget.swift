//
//  UserTarget.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation
import Moya
internal import Alamofire

enum UserTarget {
    case getUser
    case updateUser(request: UpdateUserRequestDTO)
    case deleteUser
}

extension UserTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getUser, .updateUser, .deleteUser:
            return "/user"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getUser:
            return .get
        case .updateUser:
            return .patch
        case .deleteUser:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case .getUser, .deleteUser:
            return .requestPlain
        case .updateUser(let request):
            return .requestJSONEncodable(request)
        }
    }
}
