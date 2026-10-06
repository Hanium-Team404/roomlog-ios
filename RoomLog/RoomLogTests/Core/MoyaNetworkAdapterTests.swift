//
//  MoyaNetworkAdapterTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/6/26.
//

import Testing
import Foundation
import Moya
import Alamofire
@testable import RoomLog

/// `MoyaNetworkAdapter`의 multipart 업로드 경로 테스트.
/// 스캔 zip은 수십~수백 MB라 바디를 메모리에 올리면 jetsam 위험이 있어 임시 파일로 쓰고 파일에서 전송한다.
struct MoyaNetworkAdapterTests {

    private let baseURL = URL(string: "https://\(UUID().uuidString).roomlog.test")!

    /// 어댑터는 앱 타겟 기본 격리(MainActor)라 여기서 만든다
    @MainActor
    private func makeSUT() -> MoyaNetworkAdapter {
        let client = NetworkClient(
            session: StubURLProtocol.makeSession(),
            tokenStore: StaticTokenStore(),
            refreshService: FailingRefreshService()
        )
        return MoyaNetworkAdapter(networkClient: client, baseURL: baseURL)
    }

    @Test
    func 파일_파트는_multipart_규격대로_전송되고_임시_바디_파일은_지워진다() async throws {
        let host = baseURL.host()!
        StubURLProtocol.register(host: host, statusCode: 200, body: Data("{}".utf8))
        let payload = Data((0..<300_000).map { UInt8(truncatingIfNeeded: $0 &* 7) })
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).zip")
        try payload.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let bodyFilesBefore = multipartTempFiles()

        let sut = await makeSUT()
        let response = try await sut.request(UploadTarget(baseURL: baseURL, fileURL: fileURL))

        #expect(response.statusCode == 200)
        let request = try #require(StubURLProtocol.lastRequest(host: host))
        #expect(request.method == "POST")
        #expect(request.path == "/upload")

        // Content-Type의 boundary로 바디가 조립됐는지 확인한다
        let contentType = try #require(request.contentType)
        let boundary = try #require(contentType.components(separatedBy: "boundary=").last)
        let expectedHeader = Data((
            "--\(boundary)\r\n"
            + "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
            + "Content-Type: application/octet-stream\r\n\r\n"
        ).utf8)
        let expectedFooter = Data("\r\n--\(boundary)--\r\n".utf8)
        #expect(request.body == expectedHeader + payload + expectedFooter)

        // 전송 후 어댑터가 만든 임시 바디 파일이 남지 않는다
        #expect(multipartTempFiles() == bodyFilesBefore)
    }

    /// 어댑터가 만든 임시 바디 파일 목록 (`.multipart` 확장자)
    private func multipartTempFiles() -> Set<String> {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.temporaryDirectory.path)) ?? []
        return Set(names.filter { $0.hasSuffix(".multipart") })
    }
}

// MARK: - Test Doubles

private struct UploadTarget: TargetType {
    let baseURL: URL
    let fileURL: URL

    var path: String { "/upload" }
    var method: Moya.Method { .post }
    var headers: [String: String]? { nil }
    var task: Moya.Task {
        .uploadMultipart([
            MultipartFormData(
                provider: .file(fileURL),
                name: "file",
                fileName: fileURL.lastPathComponent,
                mimeType: "application/octet-stream"
            )
        ])
    }
}

private struct StaticTokenStore: TokenStore {
    func getAccessToken() async -> String? { "at" }
    func getRefreshToken() async -> String? { "rt" }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws {}
}

private struct FailingRefreshService: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair { throw NetworkError.unauthorized }
}
