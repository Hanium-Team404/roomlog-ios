//
//  StubURLProtocol.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/6/26.
//

import Foundation
import Synchronization

/// 호스트별로 고정 응답을 돌려주고 받은 요청을 기록하는 URLProtocol.
/// 테스트마다 고유 호스트를 써야 병렬 실행 간 스텁 응답이 섞이지 않는다
final class StubURLProtocol: URLProtocol {

    struct Stub: Sendable {
        let statusCode: Int
        let body: Data
    }

    struct RecordedRequest: Sendable {
        let method: String?
        let path: String
        let contentType: String?
        let authorization: String?
        let body: Data
    }

    private struct State {
        var stubs: [String: Stub] = [:]
        var requests: [String: [RecordedRequest]] = [:]
    }

    private static let state = Mutex(State())

    static func register(host: String, statusCode: Int, body: Data) {
        state.withLock { $0.stubs[host] = Stub(statusCode: statusCode, body: body) }
    }

    static func lastRequest(host: String) -> RecordedRequest? {
        state.withLock { $0.requests[host]?.last }
    }

    static func requests(host: String) -> [RecordedRequest] {
        state.withLock { $0.requests[host] ?? [] }
    }

    /// 이 프로토콜만 쓰는 세션
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
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
            authorization: request.value(forHTTPHeaderField: "Authorization"),
            body: Self.readBody(of: request)
        )
        Self.state.withLock { $0.requests[host, default: []].append(recorded) }

        let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// URLSession은 httpBody·업로드 파일을 스트림으로 바꿔 넘기므로 둘 다 확인한다
    private static func readBody(of request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }

        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 65536)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
