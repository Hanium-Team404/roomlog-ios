//
//  TokenRefreshServiceTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 9/26/26.
//

import Testing
import Foundation
@testable import RoomLog

/// `TokenRefreshServiceImpl`의 서버 계약 테스트.
///
/// 재발급 응답 키가 틀어지면 디코딩이 조용히 실패하고, 서버는 응답 전에 기존 RT를 revoke하므로
/// 사용자는 재로그인 외에 복구할 수 없다 (#180). 실제 URLSession 경로를 URLProtocol 스텁으로 검증한다.
struct TokenRefreshServiceTests {

    /// 테스트마다 고유 호스트를 써서 병렬 실행 간 스텁 응답이 섞이지 않게 한다
    private let baseURL = URL(string: "https://\(UUID().uuidString).roomlog.test")!

    private func makeSUT(responseBody: String) -> TokenRefreshServiceImpl {
        StubURLProtocol.register(host: baseURL.host()!, statusCode: 200, body: Data(responseBody.utf8))
        return TokenRefreshServiceImpl(baseURL: baseURL, session: StubURLProtocol.makeSession())
    }

    @Test
    func snake_case_재발급_응답을_TokenPair로_디코딩한다() async throws {
        let sut = makeSUT(responseBody: """
        {"success":true,"code":200,"message":"토큰 재발급에 성공했습니다.",
         "data":{"access_token":"new-at","refresh_token":"new-rt","token_type":"Bearer"}}
        """)

        let tokenPair = try await sut.refresh("old-rt")

        // TokenPair의 Equatable은 앱 타겟 기본 격리(MainActor)라 필드로 비교한다
        #expect(tokenPair.accessToken == "new-at")
        #expect(tokenPair.refreshToken == "new-rt")
    }

    /// 서버는 요청 바디의 `refreshToken`(camelCase)·`refresh_token`(snake_case)을 모두 받는다 (#180 curl 확인).
    /// 앱은 camelCase로 보낸다.
    @Test
    func 재발급_요청은_POST_auth_refresh에_RT를_바디로_보낸다() async throws {
        let sut = makeSUT(responseBody: """
        {"success":true,"data":{"access_token":"a","refresh_token":"b"}}
        """)

        _ = try await sut.refresh("old-rt")

        let request = try #require(StubURLProtocol.lastRequest(host: baseURL.host()!))
        #expect(request.method == "POST")
        #expect(request.path == "/auth/refresh")
        #expect(request.contentType == "application/json")
        let body = try #require(JSONSerialization.jsonObject(with: request.body) as? [String: String])
        #expect(body == ["refreshToken": "old-rt"])
    }
}
