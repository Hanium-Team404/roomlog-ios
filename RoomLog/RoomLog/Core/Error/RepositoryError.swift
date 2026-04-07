//
//  RepositoryError.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

enum RepositoryError: Error, LocalizedError, Sendable, Equatable {
    
    case serverError(code: String?, message: String?)
    
    case decodingError(detail: String?)
    
    var errorDescription: String? {
        switch self {
        case .serverError(_, let message):
            return message ?? "서버 오류가 발생했습니다."
        case .decodingError(let detail):
            return "decoding error: \(detail ?? "unknown detail")"
        }
    }
    
    var code: String? {
        switch self {
        case .serverError(let code, _):
            return code
        default :
            return nil
        }
    }
    
    var errorCode: String {
        code ?? "unknown code"
    }
    
    var userMessage: String {
        errorDescription ?? "unknown error"
    }
    
    var isRetryable: Bool {
        switch self {
        case .serverError:
            return true
        case .decodingError:
            return false
        }
    }
}
