//
//  ComparisonTarget.swift
//  RoomLog
//
//  Created by minkyo on 6/4/26.
//

import Foundation
import Moya
internal import Alamofire

enum ComparisonTarget {
    case getComparisonHistories(houseId: Int)
}

extension ComparisonTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getComparisonHistories:
            return "/analyses"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getComparisonHistories:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .getComparisonHistories(let houseId):
            return .requestParameters(
                parameters: ["houseId": houseId],
                encoding: URLEncoding.queryString
            )
        }
    }
}
