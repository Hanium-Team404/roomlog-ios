//
//  BaseTargetType.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation
import Moya

protocol BaseTargetType: TargetType {}

extension BaseTargetType {
    
    /// 서버 BaseURL
    var baseURL: URL {
        guard let url = URL(string: Config.baseURL) else {
            fatalError("Invalid BASE_URL in Config")
        }
        return url
    }
    
    /// 공통 헤더
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
    
    /// 200번대 응답만 성공으로 처리
    var validationType: ValidationType {
        .successCodes
    }
}
