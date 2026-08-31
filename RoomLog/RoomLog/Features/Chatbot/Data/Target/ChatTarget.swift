//
//  ChatTarget.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation
import Moya
internal import Alamofire

enum ChatTarget {
    case startSession
    case sendMessage(sessionId: Int, message: String, guide: String?, defectId: Int?)
    case getMessages(sessionId: Int)
    /// C04. 대표 집에 등록된 하자 목록 (하자 선택 sheet용)
    case getMainHouseDefects
}

extension ChatTarget: BaseTargetType {
    var path: String {
        switch self {
        case .startSession:
            return "/chat/sessions"
        case .sendMessage(let sessionId, _, _, _), .getMessages(let sessionId):
            return "/chat/sessions/\(sessionId)/messages"
        case .getMainHouseDefects:
            return "/defects/main-house"
        }
    }

    var method: Moya.Method {
        switch self {
        case .startSession, .sendMessage:
            return .post
        case .getMessages, .getMainHouseDefects:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .sendMessage(_, let message, let guide, let defectId):
            var params: [String: Any] = ["message": message]
            if let guide {
                params["guide"] = guide
            }
            if let defectId {
                params["defect_id"] = defectId
            }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        default:
            return .requestPlain
        }
    }
}
