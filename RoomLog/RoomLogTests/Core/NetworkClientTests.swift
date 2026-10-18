//
//  NetworkClientTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/6/26.
//

import Testing
import Foundation
@testable import RoomLog

/// `NetworkClient`의 로그아웃·토큰 갱신 경합과 파일 업로드 경로 테스트.
/// 테스트 더블이 MainActor 격리라 스위트도 MainActor에서 돈다
@MainActor
struct NetworkClientTests {

    private let baseURL = URL(string: "https://\(UUID().uuidString).roomlog.test")!

    /// 로그아웃 중 갱신 응답이 늦게 도착하면 지운 토큰이 되살아난다 — 응답 후 취소 확인으로 막는다
    @Test
    func 로그아웃_뒤_도착한_갱신_응답은_토큰을_저장하지_않는다() async throws {
        let tokenStore = InMemoryTokenStore(accessToken: "old-at", refreshToken: "old-rt")
        let refreshService = GatedRefreshService()
        let sut = NetworkClient(tokenStore: tokenStore, refreshService: refreshService)

        let refresh = Task { try await sut.forceRefreshToken() }
        await refreshService.waitUntilCalled()

        try await sut.logout()
        refreshService.release(TokenPair(accessToken: "new-at", refreshToken: "new-rt"))

        await #expect(throws: CancellationError.self) { try await refresh.value }
        #expect(tokenStore.savedPairs.isEmpty)
        #expect(await tokenStore.getAccessToken() == nil)
    }

    @Test
    func 로그아웃_없이_끝난_갱신은_토큰을_저장한다() async throws {
        let tokenStore = InMemoryTokenStore(accessToken: "old-at", refreshToken: "old-rt")
        let refreshService = GatedRefreshService()
        let sut = NetworkClient(tokenStore: tokenStore, refreshService: refreshService)

        let refresh = Task { try await sut.forceRefreshToken() }
        await refreshService.waitUntilCalled()
        refreshService.release(TokenPair(accessToken: "new-at", refreshToken: "new-rt"))

        _ = try await refresh.value
        #expect(await tokenStore.getAccessToken() == "new-at")
        #expect(await tokenStore.getRefreshToken() == "new-rt")
    }

    /// 파일 업로드는 바디를 메모리에 올리지 않고 파일에서 보낸다. 401 재시도에서도 같은 파일이 다시 전송돼야 한다
    @Test
    func 파일_업로드는_파일_내용을_바디로_보내고_401_재시도에도_다시_보낸다() async throws {
        let host = baseURL.host()!
        let tokenStore = InMemoryTokenStore(accessToken: "old-at", refreshToken: "old-rt")
        let refreshService = GatedRefreshService(immediate: TokenPair(accessToken: "new-at", refreshToken: "new-rt"))
        let sut = NetworkClient(session: StubURLProtocol.makeSession(), tokenStore: tokenStore, refreshService: refreshService)

        let payload = Data((0..<200_000).map { UInt8(truncatingIfNeeded: $0) })
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).bin")
        try payload.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        // 첫 응답은 401 → 갱신 → 재시도. 스텁은 호스트당 응답 하나라 두 번째도 401로 끝난다
        StubURLProtocol.register(host: host, statusCode: 401, body: Data())
        var request = URLRequest(url: baseURL.appending(path: "/upload"))
        request.httpMethod = "POST"

        await #expect(throws: NetworkError.self) {
            _ = try await sut.upload(request, fromFile: fileURL)
        }

        let requests = StubURLProtocol.requests(host: host)
        #expect(requests.count == 2)
        #expect(requests.allSatisfy { $0.body == payload })
        #expect(requests.map(\.authorization) == ["Bearer old-at", "Bearer new-at"])
    }

    /// 로그인처럼 토큰 없이 보낸 요청의 401은 자격 증명 거부다.
    /// 갱신으로 돌리면 refresh token이 없어 `unauthorized`로 바뀌고 서버가 보낸 에러 코드가 사라진다
    @Test(.bug("https://github.com/Hanium-Team404/roomlog-ios/issues/227"))
    func 인증_불필요_요청의_401은_갱신_없이_본문을_보존한다() async throws {
        let host = baseURL.host()!
        let tokenStore = InMemoryTokenStore(accessToken: nil, refreshToken: nil)
        let refreshService = GatedRefreshService(immediate: TokenPair(accessToken: "new-at", refreshToken: "new-rt"))
        let sut = NetworkClient(session: StubURLProtocol.makeSession(), tokenStore: tokenStore, refreshService: refreshService)

        let body = Data(#"{"isSuccess":false,"error":{"code":"AUTH_001"}}"#.utf8)
        StubURLProtocol.register(host: host, statusCode: 401, body: body)
        var request = URLRequest(url: baseURL.appending(path: "/auth/login"))
        request.httpMethod = "POST"

        do {
            _ = try await sut.request(request)
            Issue.record("401 응답은 오류로 전달돼야 한다")
        } catch NetworkError.httpError(let statusCode, let data) {
            #expect(statusCode == 401)
            #expect(data == body, "서버 본문이 그대로 보존돼야 한다")
        } catch {
            Issue.record("예상과 다른 오류: \(error)")
        }

        let requests = StubURLProtocol.requests(host: host)
        #expect(requests.count == 1, "토큰 갱신 후 재시도가 없어야 한다")
        #expect(requests.first?.authorization == nil)
    }
}

// MARK: - Test Doubles
// 프로토콜이 앱 타겟 기본 격리(MainActor)를 물려받아 actor로는 채택할 수 없다 — MainActor 클래스로 둔다

/// 메모리 토큰 저장소. 저장 호출을 기록한다
@MainActor
private final class InMemoryTokenStore: TokenStore {
    private var accessToken: String?
    private var refreshToken: String?
    private(set) var savedPairs: [(access: String, refresh: String)] = []

    init(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func getAccessToken() async -> String? { accessToken }
    func getRefreshToken() async -> String? { refreshToken }

    func save(accessToken: String, refreshToken: String) async throws {
        savedPairs.append((accessToken, refreshToken))
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clear() async throws {
        accessToken = nil
        refreshToken = nil
    }
}

/// `release`가 호출될 때까지 `refresh`를 붙잡아 두는 갱신 서비스. 취소돼도 깨어나지 않아 "늦게 도착한 응답"을 흉내 낸다
@MainActor
private final class GatedRefreshService: TokenRefreshService {
    private let immediate: TokenPair?
    private var pending: CheckedContinuation<TokenPair, Never>?
    private var calledWaiters: [CheckedContinuation<Void, Never>] = []
    private var isCalled = false

    /// `immediate`를 주면 붙잡지 않고 바로 돌려준다
    init(immediate: TokenPair? = nil) {
        self.immediate = immediate
    }

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        if let immediate { return immediate }
        isCalled = true
        calledWaiters.forEach { $0.resume() }
        calledWaiters.removeAll()
        return await withCheckedContinuation { pending = $0 }
    }

    func waitUntilCalled() async {
        if isCalled { return }
        await withCheckedContinuation { calledWaiters.append($0) }
    }

    func release(_ tokenPair: TokenPair) {
        pending?.resume(returning: tokenPair)
        pending = nil
    }
}
