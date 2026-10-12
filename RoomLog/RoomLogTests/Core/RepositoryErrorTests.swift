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

    @Test func 서버장애_5xx는_재시도_가능하다() {
        #expect(RepositoryError.serverError(code: 500, message: nil, errorCode: nil).isRetryable)
        #expect(RepositoryError.serverError(code: 503, message: nil, errorCode: nil).isRetryable)
        #expect(!RepositoryError.serverError(code: nil, message: nil, errorCode: nil).isRetryable)
    }

    /// 408(요청 타임아웃)·429(레이트 리밋)는 잠시 뒤 다시 보내면 성공할 수 있다. 그 외 4xx는 결과가 같으므로 불가
    @Test(arguments: [408, 429])
    func 일시적_4xx는_재시도_가능하다(code: Int) {
        #expect(RepositoryError.serverError(code: code, message: nil, errorCode: nil).isRetryable)
    }

    @Test(arguments: [400, 401, 403, 404, 409, 422])
    func 비즈니스_거부_4xx는_재시도_불가하다(code: Int) {
        #expect(!RepositoryError.serverError(code: code, message: nil, errorCode: nil).isRetryable)
    }

    @Test func NetworkError_httpError도_같은_재시도_규칙을_따른다() {
        #expect(NetworkError.httpError(statusCode: 503, data: Data()).isRetryable)
        #expect(NetworkError.httpError(statusCode: 429, data: Data()).isRetryable)
        #expect(!NetworkError.httpError(statusCode: 404, data: Data()).isRetryable)
        #expect(!NetworkError.unauthorized.isRetryable)
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

    @Test(arguments: [URLError.Code.networkConnectionLost, .cancelled])
    func URLError는_transportError로_정규화된다(code: URLError.Code) {
        let normalized = RepositoryError.normalize(URLError(code))
        #expect(normalized == .transportError(code: code))
    }

    @Test func CancellationError는_취소_코드를_보존한다() {
        #expect(RepositoryError.normalize(CancellationError()) == .transportError(code: .cancelled))
    }

    @Test func RepositoryError는_그대로_통과한다() {
        let original = RepositoryError.serverError(code: 404, message: "not found", errorCode: nil)
        #expect(RepositoryError.normalize(original) == original)
    }

    @Test(arguments: [
        ("CHAT_001", ServerErrorCode.chatSessionNotFound, 404),
        ("CHAT_002", ServerErrorCode.chatSessionAccessDenied, 403),
        ("ANALYSIS_001", ServerErrorCode.analysisNotFound, 404)
    ])
    func HTTP_에러_본문의_서버_코드와_메시지를_복원한다(
        rawCode: String,
        expectedCode: ServerErrorCode,
        statusCode: Int
    ) {
        let body = Data("""
        {"message":"서버 상세 메시지","error":{"code":"\(rawCode)"}}
        """.utf8)

        let normalized = RepositoryError.normalize(NetworkError.httpError(statusCode: statusCode, data: body))

        #expect(normalized == .serverError(code: statusCode, message: "서버 상세 메시지", errorCode: expectedCode))
        #expect(normalized.isRetryable == false)
    }

    @Test func HTTP_상태가_본문의_code보다_우선한다() {
        let body = Data("""
        {"code":400,"message":"일시적인 서버 장애","error":{"code":"COMMON_500"},"data":[1,2]}
        """.utf8)

        let normalized = RepositoryError.normalize(NetworkError.httpError(statusCode: 503, data: body))

        #expect(normalized == .serverError(code: 503, message: "일시적인 서버 장애", errorCode: .commonServerError))
        #expect(normalized.isRetryable)
    }

    @Test(arguments: ["", "<html>Service Unavailable</html>", "{", "{}"])
    func HTTP_에러_본문을_읽을_수_없어도_상태와_재시도_가능성을_보존한다(body: String) {
        let original = NetworkError.httpError(statusCode: 503, data: Data(body.utf8))

        let normalized = RepositoryError.normalize(original)

        #expect(normalized == .serverError(code: 503, message: original.errorDescription, errorCode: nil))
        #expect(normalized.isRetryable)
    }

    @Test func 알수없는_서버_코드는_내부_메시지를_사용자에게_노출하지_않는다() {
        let body = Data("""
        {"message":"internal detail","error":{"code":"FUTURE_001"}}
        """.utf8)

        let normalized = RepositoryError.normalize(NetworkError.httpError(statusCode: 400, data: body))

        #expect(normalized == .serverError(code: 400, message: "internal detail", errorCode: .unknown))
        #expect(normalized.userMessage == "서버 오류가 발생했습니다.")
    }

    @Test func unauthorized는_인증_실패로_정규화된다() {
        let original = NetworkError.unauthorized

        let normalized = RepositoryError.normalize(original)

        #expect(normalized == .serverError(code: 401, message: original.errorDescription, errorCode: .commonUnauthorized))
        #expect(normalized.isRetryable == false)
    }

    @Test func 잘못된_네트워크_응답과_갱신_응답은_디코딩_오류로_정규화된다() {
        #expect(RepositoryError.normalize(NetworkError.invalidResponse) == .decodingError(detail: NetworkError.invalidResponse.errorDescription))
        #expect(RepositoryError.normalize(TokenRefreshError.invalidResponse) == .decodingError(detail: TokenRefreshError.invalidResponse.errorDescription))
    }

    @Test(arguments: [
        (401, ServerErrorCode.commonUnauthorized as ServerErrorCode?, false),
        (403, ServerErrorCode.commonForbidden as ServerErrorCode?, false),
        (503, nil as ServerErrorCode?, true),
        (429, nil as ServerErrorCode?, true)
    ])
    func 토큰_갱신_HTTP_오류는_실제_상태와_인증_의미를_보존한다(
        statusCode: Int,
        expectedCode: ServerErrorCode?,
        isRetryable: Bool
    ) {
        let original = TokenRefreshError.serverError(statusCode: statusCode)

        let normalized = RepositoryError.normalize(original)

        #expect(normalized == .serverError(code: statusCode, message: original.errorDescription, errorCode: expectedCode))
        #expect(normalized.isRetryable == isRetryable)
    }

    @Test(arguments: ["토큰 갱신 거부" as String?, nil])
    func 토큰_갱신_실패는_메시지를_보존하고_인증_실패로_단정하지_않는다(message: String?) {
        let original = TokenRefreshError.refreshFailed(message: message)

        let normalized = RepositoryError.normalize(original)

        #expect(normalized == .serverError(code: nil, message: original.errorDescription, errorCode: nil))
        #expect(normalized.isRetryable == false)
    }

    @Test func 알수없는_에러는_decodingError로_폴백한다() {
        let normalized = RepositoryError.normalize(NSError(domain: "test", code: -1))
        guard case .decodingError = normalized else {
            Issue.record("decodingError로 폴백해야 하는데 \(normalized)")
            return
        }
    }
}
