//
//  AuthTarget.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation
import Moya
internal import Alamofire

enum AuthTarget {
    case login(request: LoginRequestDTO)
    case signup(request: SignUpRequestDTO)
}

extension AuthTarget: BaseTargetType {
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .signup:
            return "/auth/signup"
        }
    }

    var method: Moya.Method {
        .post
    }

    var task: Moya.Task {
        switch self {
        case .login(let request):
            return .requestJSONEncodable(request)
        case .signup(let request):
            return .requestJSONEncodable(request)
        }
    }
}
