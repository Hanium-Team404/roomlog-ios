//
//  ScanTarget.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation
import Moya
internal import Alamofire

enum ScanTarget {
    case uploadScan(roomId: Int, zipFileURL: URL)
}

extension ScanTarget: BaseTargetType {
    var path: String {
        switch self {
        case .uploadScan(let roomId, _):
            return "/rooms/\(roomId)/scans"
        }
    }

    var method: Moya.Method {
        .post
    }

    var task: Moya.Task {
        switch self {
        case .uploadScan(_, let zipFileURL):
            let formData = MultipartFormData(
                provider: .file(zipFileURL),
                name: "file",
                fileName: "scan.zip",
                mimeType: "application/zip"
            )
            return .uploadMultipart([formData])
        }
    }
}
