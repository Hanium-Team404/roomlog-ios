//
//  EstimateTarget.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation
import Moya
internal import Alamofire

enum EstimateTarget {
    case getRepairShops(analysisId: Int, type: String?, radius: String?, sort: String?)
    case getRepairShopsByRoom(roomId: Int, type: String?, radius: String?, sort: String?)
    case createEstimate(request: CreateEstimateRequestDTO)
}

extension EstimateTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getRepairShops(let analysisId, _, _, _):
            return "/analyses/\(analysisId)/repair-shops"
        case .getRepairShopsByRoom(let roomId, _, _, _):
            return "/rooms/\(roomId)/repair-shops"
        case .createEstimate:
            return "/estimates"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getRepairShops, .getRepairShopsByRoom:
            return .get
        case .createEstimate:
            return .post
        }
    }

    var task: Moya.Task {
        switch self {
        case .getRepairShops(_, let type, let radius, let sort),
             .getRepairShopsByRoom(_, let type, let radius, let sort):
            var params: [String: Any] = [:]
            if let type { params["type"] = type }
            if let radius { params["radius"] = radius }
            if let sort { params["sort"] = sort }
            return params.isEmpty ? .requestPlain : .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .createEstimate(let request):
            return .requestJSONEncodable(request)
        }
    }
}
