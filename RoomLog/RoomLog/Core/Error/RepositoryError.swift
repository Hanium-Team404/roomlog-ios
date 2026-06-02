//
//  RepositoryError.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

enum RepositoryError: Error, LocalizedError, Sendable, Equatable {

    case serverError(code: Int?, message: String?, errorCode: ServerErrorCode?)

    case decodingError(detail: String?)

    var errorDescription: String? {
        switch self {
        case .serverError(_, _, let errorCode):
            // 서버 에러 코드가 있으면 해당 메시지 우선 사용
            if let errorCode, errorCode != .unknown {
                return errorCode.userMessage
            }
            return message ?? "서버 오류가 발생했습니다."
        case .decodingError(let detail):
            return "decoding error: \(detail ?? "unknown detail")"
        }
    }

    var code: Int? {
        switch self {
        case .serverError(let code, _, _):
            return code
        default:
            return nil
        }
    }

    var message: String? {
        switch self {
        case .serverError(_, let message, _):
            return message
        default:
            return nil
        }
    }

    var serverErrorCode: ServerErrorCode? {
        switch self {
        case .serverError(_, _, let errorCode):
            return errorCode
        default:
            return nil
        }
    }

    var userMessage: String {
        errorDescription ?? "알 수 없는 오류가 발생했습니다."
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
