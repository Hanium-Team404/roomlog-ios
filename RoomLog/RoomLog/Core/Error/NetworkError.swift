//
//  NetworkError.swift
//  RoomLog
//

import Foundation

enum NetworkError: Error, LocalizedError, Sendable {

    /// URLResponse가 HTTPURLResponse로 변환 불가
    case invalidResponse

    /// 인증 실패 (401 재시도 초과 또는 refreshToken 없음)
    case unauthorized

    /// HTTP 에러 응답 (2xx 외 상태 코드)
    case httpError(statusCode: Int, data: Data)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "유효하지 않은 서버 응답입니다."
        case .unauthorized:
            return "인증이 필요합니다. 다시 로그인해 주세요."
        case .httpError(let statusCode, _):
            return "HTTP 오류가 발생했습니다. (상태 코드: \(statusCode))"
        }
    }

    var statusCode: Int? {
        switch self {
        case .httpError(let code, _):
            return code
        default:
            return nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .httpError(let code, _):
            return code >= 500
        default:
            return false
        }
    }
}
