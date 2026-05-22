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
    case uploadScan(houseId: Int, fileURL: URL)
    case getScanStatus(scanId: Int)
    case getScanPreview(scanId: Int)
    case cancelScan(scanId: Int)
}

extension ScanTarget: BaseTargetType {
    var path: String {
        switch self {
        case .uploadScan:
            return "/scans"
        case .getScanStatus(let scanId):
            return "/scans/\(scanId)/status"
        case .getScanPreview(let scanId):
            return "/scans/\(scanId)/preview"
        case .cancelScan(let scanId):
            return "/scans/\(scanId)/cancel"
        }
    }

    var method: Moya.Method {
        switch self {
        case .uploadScan, .cancelScan:
            return .post
        case .getScanStatus, .getScanPreview:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .uploadScan(let houseId, let fileURL):
            let formData = MultipartFormData(
                provider: .file(fileURL),
                name: "file",
                fileName: fileURL.lastPathComponent,
                mimeType: "application/octet-stream"
            )
            return .uploadCompositeMultipart(
                [formData],
                urlParameters: ["house_id": houseId]
            )
        case .getScanStatus, .getScanPreview, .cancelScan:
            return .requestPlain
        }
    }
}
