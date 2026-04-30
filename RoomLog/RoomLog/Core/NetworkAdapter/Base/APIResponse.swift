//
//  APIResponse.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

struct APIResponse<T: Codable>: Codable {
    // MARK: - Property
    
    /// 요청 성공 여부
    let isSuccess: Bool
    /// 응답 코드
    let code: Int?
    /// 응답 메세지
    let message: String?
    /// 응답 결과
    let result: T?
    
    
    private enum CodingKeys: String, CodingKey {
        case isSuccess = "success"
        case code
        case message
        case result = "data"
    }
}

extension APIResponse {
    func unwrap() throws -> T {
        guard isSuccess else {
            throw RepositoryError.serverError(code: code, message: message)
        }
        
        if let result {
            return result
        }
        
        if T.self == EmptyResult.self, let empty = EmptyResult() as? T {
            return empty
        }
        
        throw RepositoryError.serverError(code: code, message: message)
    }
}

/// 결과 데이터가 없는 응답에서 사용
struct EmptyResult: Codable, Sendable, Equatable {}
