//
//  TokenRefreshServiceTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 9/26/26.
//

import Testing
import Foundation
import Synchronization
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
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return TokenRefreshServiceImpl(baseURL: baseURL, session: URLSession(configuration: configuration))
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

// MARK: - URLProtocol Stub

/// 호스트별로 고정 응답을 돌려주고 받은 요청을 기록하는 URLProtocol
private final class StubURLProtocol: URLProtocol {

    struct Stub: Sendable {
        let statusCode: Int
        let body: Data
    }

    struct RecordedRequest: Sendable {
        let method: String?
        let path: String
        let contentType: String?
        let body: Data
    }

    private struct State {
        var stubs: [String: Stub] = [:]
        var requests: [String: RecordedRequest] = [:]
    }

    private static let state = Mutex(State())

    static func register(host: String, statusCode: Int, body: Data) {
        state.withLock { $0.stubs[host] = Stub(statusCode: statusCode, body: body) }
    }

    static func lastRequest(host: String) -> RecordedRequest? {
        state.withLock { $0.requests[host] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let host = url.host(),
              let stub = Self.state.withLock({ $0.stubs[host] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        let recorded = RecordedRequest(
            method: request.httpMethod,
            path: url.path(),
            contentType: request.value(forHTTPHeaderField: "Content-Type"),
            body: Self.readBody(of: request)
        )
        Self.state.withLock { $0.requests[host] = recorded }

        let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// URLSession은 httpBody를 스트림으로 바꿔 넘기므로 둘 다 확인한다
    private static func readBody(of request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }

        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
