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
    case getDefectReportDetail(roomId: Int, reportId: Int)
}

extension DefectTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getDefectRoomData:
            return "/defects"
        case .getDefectReport(let roomId):
            return "/rooms/\(roomId)/defects"
        case .getDefectReportDetail(let roomId, let reportId):
            return "/rooms/\(roomId)/defects/\(reportId)"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Moya.Task {
        return .requestPlain
    }
}
