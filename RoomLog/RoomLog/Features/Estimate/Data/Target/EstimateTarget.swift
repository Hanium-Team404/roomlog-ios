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
    case previewEstimate(request: EstimatePreviewRequestDTO)
    case createEstimate(request: CreateEstimateRequestDTO)
    case getEstimates(roomId: Int)
    case getEstimateDetail(estimateId: Int)
    case completeRepair(estimateId: Int, request: CompleteRepairRequestDTO)
}

extension EstimateTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getRepairShops(let analysisId, _, _, _):
            return "/analyses/\(analysisId)/repair-shops"
        case .getRepairShopsByRoom(let roomId, _, _, _):
            return "/rooms/\(roomId)/repair-shops"
        case .previewEstimate:
            return "/estimates/preview"
        case .createEstimate, .getEstimates:
            return "/estimates"
        case .getEstimateDetail(let estimateId):
            return "/estimates/\(estimateId)"
        case .completeRepair(let estimateId, _):
            return "/estimates/\(estimateId)/repairs"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getRepairShops, .getRepairShopsByRoom, .getEstimates, .getEstimateDetail:
            return .get
        case .previewEstimate, .createEstimate, .completeRepair:
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
        case .previewEstimate(let request):
            return .requestJSONEncodable(request)
        case .createEstimate(let request):
            return .requestJSONEncodable(request)
        case .getEstimates(let roomId):
            return .requestParameters(parameters: ["roomId": roomId], encoding: URLEncoding.queryString)
        case .getEstimateDetail:
            return .requestPlain
        case .completeRepair(_, let request):
            return .requestJSONEncodable(request)
        }
    }
}
