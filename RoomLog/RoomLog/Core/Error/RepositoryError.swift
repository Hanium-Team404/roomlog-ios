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

    /// 요청이 서버에 도달하지 못한 전송 계층 실패 (오프라인, 타임아웃, 연결 끊김 등).
    /// 서버 상태·저장된 데이터와 무관한 실패이므로 항상 재시도 가능하다.
    case transportError(code: URLError.Code)

    /// 로그·디버깅용 상세 설명. 사용자 노출 문구는 `userMessage`를 사용한다.
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
        case .transportError(let code):
            return "transport error: URLError(\(code.rawValue))"
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

    /// 사용자에게 표시할 문구. 디코딩 덤프·서버 raw message 같은 내부 상세는 `errorDescription`(로그)에만 남긴다.
    var userMessage: String {
        switch self {
        case .serverError(_, _, let errorCode):
            // 앱이 검수한 코드별 문구만 노출 — 서버가 보낸 message는 통제 밖이라 로그로만
            if let errorCode, errorCode != .unknown {
                return errorCode.userMessage
            }
            return "서버 오류가 발생했습니다."
        case .decodingError:
            return "일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요."
        case .transportError:
            return "네트워크 연결을 확인해 주세요."
        }
    }

    /// 재시도 가능 여부. 전송 실패·서버 장애(5xx)만 재시도 가능하고,
    /// 비즈니스 거부(4xx)·디코딩 실패는 다시 시도해도 결과가 같으므로 불가.
    var isRetryable: Bool {
        switch self {
        case .transportError:
            return true
        case .serverError(let code, _, _):
            return (code ?? 0) >= 500
        case .decodingError:
            return false
        }
    }
}

// MARK: - Normalize

extension RepositoryError {
    /// 하위 계층의 임의 에러를 도메인 에러로 정규화한다.
    /// Repository 경계 위로는 이 타입만 올라가도록 하는 단일 변환 지점.
    static func normalize(_ error: Error) -> RepositoryError {
        switch error {
        case let repositoryError as RepositoryError:
            return repositoryError
        case let urlError as URLError:
            return .transportError(code: urlError.code)
        case is CancellationError:
            return .transportError(code: .cancelled)
        case let networkError as NetworkError:
            return .serverError(
                code: networkError.statusCode,
                message: networkError.errorDescription,
                errorCode: nil
            )
        default:
            return .decodingError(detail: String(describing: error))
        }
    }
}
