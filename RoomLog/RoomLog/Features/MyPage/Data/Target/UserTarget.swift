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
}

extension UserTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getUser:
            return "/user"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getUser:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .getUser:
            return .requestPlain
        }
    }
}
