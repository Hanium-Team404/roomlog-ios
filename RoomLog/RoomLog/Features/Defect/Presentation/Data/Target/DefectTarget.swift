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
}

extension DefectTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getDefectRoomData:
            return "/rooms"
        case .getDefectReport(let roomId), .getDefectReportDetail(let roomId):
            return "/rooms/\(roomId)/defects"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Moya.Task {
        return .requestPlain
    }
}
