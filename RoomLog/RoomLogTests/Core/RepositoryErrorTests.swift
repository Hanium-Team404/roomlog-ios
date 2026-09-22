//
//  RepositoryErrorTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 9/22/26.
//

import Testing
import Foundation
@testable import RoomLog

struct RepositoryErrorTests {

    // MARK: - isRetryable

    @Test func 전송실패는_재시도_가능하다() {
        #expect(RepositoryError.transportError(code: .notConnectedToInternet).isRetryable)
        #expect(RepositoryError.transportError(code: .timedOut).isRetryable)
    }

    @Test func 서버장애_5xx만_재시도_가능하다() {
        #expect(RepositoryError.serverError(code: 500, message: nil, errorCode: nil).isRetryable)
        #expect(RepositoryError.serverError(code: 503, message: nil, errorCode: nil).isRetryable)
        #expect(!RepositoryError.serverError(code: 400, message: nil, errorCode: nil).isRetryable)
        #expect(!RepositoryError.serverError(code: nil, message: nil, errorCode: nil).isRetryable)
    }

    @Test func 디코딩실패는_재시도_불가하다() {
        #expect(!RepositoryError.decodingError(detail: "detail").isRetryable)
    }

    // MARK: - userMessage

    @Test func 디코딩실패_userMessage는_내부_덤프를_노출하지_않는다() {
        let error = RepositoryError.decodingError(detail: "keyNotFound(CodingKeys.scanId)")
        #expect(!error.userMessage.contains("keyNotFound"))
    }

    @Test func 서버에러_userMessage는_서버_raw_message를_노출하지_않는다() {
        let unknownCode = RepositoryError.serverError(code: 500, message: "internal detail", errorCode: nil)
        #expect(unknownCode.userMessage == "서버 오류가 발생했습니다.")

        let knownCode = RepositoryError.serverError(code: 404, message: "raw", errorCode: .scanNotFound)
        #expect(knownCode.userMessage == ServerErrorCode.scanNotFound.userMessage)
    }

    // MARK: - normalize

    @Test func URLError는_transportError로_정규화된다() {
        let normalized = RepositoryError.normalize(URLError(.networkConnectionLost))
        #expect(normalized == .transportError(code: .networkConnectionLost))
    }

    @Test func RepositoryError는_그대로_통과한다() {
        let original = RepositoryError.serverError(code: 404, message: "not found", errorCode: nil)
        #expect(RepositoryError.normalize(original) == original)
    }

    @Test func 알수없는_에러는_decodingError로_폴백한다() {
        let normalized = RepositoryError.normalize(NSError(domain: "test", code: -1))
        guard case .decodingError = normalized else {
            Issue.record("decodingError로 폴백해야 하는데 \(normalized)")
            return
        }
    }
}
