//
//  DefectTarget.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation
import Moya
internal import Alamofire

enum DefectTarget {
    case getDefectRoomData
    case getDefectReport(roomId: Int)
    case getDefectReportDetail(roomId: Int)
    case createAnalysis(inRoomId: Int, outRoomId: Int?)
    case getAnalysisStatus(analysisId: Int)
    case getAnalysisResult(analysisId: Int)
}

extension DefectTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getDefectRoomData:
            return "/rooms"
        case .getDefectReport(let roomId), .getDefectReportDetail(let roomId):
            return "/rooms/\(roomId)/defects"
        case .createAnalysis:
            return "/analyses"
        case .getAnalysisStatus(let analysisId):
            return "/analyses/\(analysisId)/status"
        case .getAnalysisResult(let analysisId):
            return "/analyses/\(analysisId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createAnalysis:
            return .post
        default:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .createAnalysis(let inRoomId, let outRoomId):
            var params: [String: Any] = ["in_room_id": inRoomId]
            if let outRoomId {
                params["out_room_id"] = outRoomId
            }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        default:
            return .requestPlain
        }
    }
}
