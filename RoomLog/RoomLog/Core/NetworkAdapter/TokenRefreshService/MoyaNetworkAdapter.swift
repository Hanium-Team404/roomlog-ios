//
//  MoyaNetworkAdapter.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation
import Moya
internal import Alamofire

/// Moya의 TargetType을 NetworkClient와 연동하는 어댑터
///
/// TargetType -> URLRequest로 변환
struct MoyaNetworkAdapter {
    private let networkClient: NetworkClient
    
    private let baseURL: URL
    
    init(networkClient: NetworkClient, baseURL: URL) {
        self.networkClient = networkClient
        self.baseURL = baseURL
    }
    
    /// Moya API를 요청하고 Response를 반환한다.
    /// - Parameter uploadProgress: 전달하면 요청 바디 전송량을 반영한다
    func request<T: TargetType>(_ target: T, uploadProgress: Progress? = nil) async throws -> Moya.Response {
        // Moya TargetType을 URLRequest로 변환
        let (urlRequest, body) = try buildURLRequest(target)
        // 어댑터가 만든 임시 바디 파일은 요청(401 재시도 포함)이 끝난 뒤 지운다
        defer {
            if case .file(let url, isTemporary: true) = body {
                try? FileManager.default.removeItem(at: url)
            }
        }

        #if DEBUG
        logRequest(urlRequest)
        #endif

        do {
            // NetworkClient(토큰 자동 갱신 지원)를 통해 요청
            let delegate = uploadProgress.map { UploadProgressDelegate(progress: $0) }
            let (data, httpResponse) = switch body {
            case .inline:
                try await networkClient.request(urlRequest, delegate: delegate)
            case .file(let url, _):
                try await networkClient.upload(urlRequest, fromFile: url, delegate: delegate)
            }

            #if DEBUG
            logResponse(httpResponse, data: data, request: urlRequest)
            #endif

            // Moya의 Response 형태로 포장해서 반환
            let response = Response(
                statusCode: httpResponse.statusCode,
                data: data,
                request: urlRequest,
                response: httpResponse
            )
            return response
        } catch {
            #if DEBUG
            print("🔴 [Network] ERROR \(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "")")
            print("  → \(error.localizedDescription)")
            #endif
            throw error
        }
    }
}

// MARK: - Decoded Request (Repository 진입점)

extension MoyaNetworkAdapter {
    /// 요청 → `APIResponse` 디코딩 → `unwrap`까지 한 번에 수행한다.
    /// 실패는 전부 `RepositoryError`로 정규화되므로, Repository는 이 메서드만 쓰면
    /// typed throws(`throws(RepositoryError)`)를 그대로 전파할 수 있다.
    func requestDecoded<DTO: Codable>(
        _ target: some TargetType,
        as type: DTO.Type = DTO.self,
        decoder: JSONDecoder = JSONDecoder(),
        uploadProgress: Progress? = nil
    ) async throws(RepositoryError) -> DTO {
        do {
            let response = try await request(target, uploadProgress: uploadProgress)
            let dto = try decoder.decode(APIResponse<DTO>.self, from: response.data)
            return try dto.unwrap()
        } catch {
            throw RepositoryError.normalize(error)
        }
    }
}

// MARK: - Debug Logging

#if DEBUG
extension MoyaNetworkAdapter {
    private func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        print("🟡 [Network] → \(method) \(url)")
        if let body = request.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let str = String(data: pretty, encoding: .utf8) {
            print("  📦 Body: \(str)")
        }
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data, request: URLRequest) {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        let status = response.statusCode
        let icon = (200..<300).contains(status) ? "🟢" : "🔴"
        print("\(icon) [Network] ← \(status) \(method) \(url)")

        // 에러 응답이면 서버 에러 코드 파싱
        if !(200..<300).contains(status) {
            if let errorInfo = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                let code = errorInfo.error?.code ?? "없음"
                let message = errorInfo.message ?? ""
                let serverError = ServerErrorCode(rawValue: code)
                print("  ⚠️ [\(code)] \(serverError.userMessage)")
                if !message.isEmpty {
                    print("  💬 서버 메시지: \(message)")
                }
            }
        }

        if let str = String(data: data, encoding: .utf8) {
            let preview = str.prefix(500)
            print("  📄 Response: \(preview)\(str.count > 500 ? "..." : "")")
        }
    }
}
#endif

// MARK: - URLRequest Builder

extension MoyaNetworkAdapter {

    /// 대용량 zip 업로드가 기본 60초 요청 타임아웃을 초과할 수 있어 업로드 요청만 상향한다
    private static let uploadTimeoutInterval: TimeInterval = 300

    /// 요청 바디의 위치. 업로드는 수십~수백 MB zip을 메모리에 올리지 않도록 파일에서 바로 전송한다
    private enum RequestBody {
        /// `request.httpBody`에 실려 있다
        case inline
        /// 파일에서 전송한다. `isTemporary`면 어댑터가 만든 것이므로 전송 후 삭제한다
        case file(URL, isTemporary: Bool)
    }

    private func buildURLRequest<T: TargetType>(_ target: T) throws -> (URLRequest, RequestBody) {
        // 1. URL 구성 (baseURL + path)
        let url = target.baseURL.appending(path: target.path)

        // 2. URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue
        var body: RequestBody = .inline

        // 3. Headers 설정
        target.headers?.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        // 4. Task에 따라 Body 설정
        switch target.task {
        case .requestPlain:
            break

        case .requestJSONEncodable(let encodable):
            request.httpBody = try JSONEncoder().encode(AnyEncodable(encodable))

        case .requestParameters(let parameters, let encoding):
            request = try encodeParameters(request, parameters: parameters, encoding: encoding)
            
        case .requestCompositeParameters(let bodyParameters, let bodyEncoding, let urlParameters):
            request = try encodeParameters(request, parameters: bodyParameters, encoding: bodyEncoding)
            request = try encodeURLParameters(request, parameters: urlParameters)
            
        case .requestData(let data):
            request.httpBody = data

        case .requestCustomJSONEncodable(let encodable, let encoder):
            request.httpBody = try encoder.encode(AnyEncodable(encodable))

        case .requestCompositeData(let bodyData, let urlParameters):
            request.httpBody = bodyData
            request = try encodeURLParameters(request, parameters: urlParameters)

        case .uploadFile(let fileURL):
            body = .file(fileURL, isTemporary: false)
            request.timeoutInterval = Self.uploadTimeoutInterval

        case .uploadMultipart(let multipartData):
            let (bodyURL, boundary) = try writeMultipartBody(multipartData)
            body = .file(bodyURL, isTemporary: true)
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = Self.uploadTimeoutInterval

        case .uploadCompositeMultipart(let multipartData, let urlParameters):
            let (bodyURL, boundary) = try writeMultipartBody(multipartData)
            body = .file(bodyURL, isTemporary: true)
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request = try encodeURLParameters(request, parameters: urlParameters)
            request.timeoutInterval = Self.uploadTimeoutInterval

        case .downloadDestination, .downloadParameters:
            throw MoyaAdapterError.unsupportedTask(target.task)
        }

        return (request, body)
    }

    /// 파일 파트를 복사할 때 한 번에 읽는 크기
    private static let multipartChunkSize = 1 << 20

    /// multipart 바디를 임시 파일로 쓴다. 파일 파트는 청크 단위로 복사하므로 메모리 사용량이 zip 크기와 무관하다.
    /// 쓰다가 실패하면 임시 파일을 지우고 던진다
    private func writeMultipartBody(_ parts: [Moya.MultipartFormData]) throws -> (URL, String) {
        let boundary = "Boundary-\(UUID().uuidString)"
        let bodyURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).multipart")
        guard FileManager.default.createFile(atPath: bodyURL.path, contents: nil) else {
            throw MoyaAdapterError.multipartBodyWriteFailed
        }

        do {
            let handle = try FileHandle(forWritingTo: bodyURL)
            defer { try? handle.close() }
            let crlf = "\r\n"

            for part in parts {
                try handle.write(contentsOf: Data("--\(boundary)\(crlf)".utf8))

                var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
                if let fileName = part.fileName {
                    disposition += "; filename=\"\(fileName)\""
                }
                try handle.write(contentsOf: Data("\(disposition)\(crlf)".utf8))

                if let mimeType = part.mimeType {
                    try handle.write(contentsOf: Data("Content-Type: \(mimeType)\(crlf)".utf8))
                }

                try handle.write(contentsOf: Data(crlf.utf8))

                switch part.provider {
                case .data(let data):
                    try handle.write(contentsOf: data)
                case .file(let fileURL):
                    let source = try FileHandle(forReadingFrom: fileURL)
                    defer { try? source.close() }
                    while let chunk = try source.read(upToCount: Self.multipartChunkSize), !chunk.isEmpty {
                        try handle.write(contentsOf: chunk)
                    }
                case .stream(let stream, _):
                    let bufferSize = 65536
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                    defer { buffer.deallocate() }
                    stream.open()
                    defer { stream.close() }
                    while stream.hasBytesAvailable {
                        let read = stream.read(buffer, maxLength: bufferSize)
                        if read < 0 { throw MoyaAdapterError.streamReadFailed }
                        if read == 0 { break }
                        try handle.write(contentsOf: Data(bytes: buffer, count: read))
                    }
                }

                try handle.write(contentsOf: Data(crlf.utf8))
            }

            try handle.write(contentsOf: Data("--\(boundary)--\(crlf)".utf8))
        } catch {
            try? FileManager.default.removeItem(at: bodyURL)
            throw error
        }

        return (bodyURL, boundary)
    }

    private func encodeParameters(
        _ request: URLRequest,
        parameters: [String: Any],
        encoding: ParameterEncoding
    ) throws -> URLRequest {
        try encoding.encode(request, with: parameters)
    }

    private func encodeURLParameters(
        _ request: URLRequest,
        parameters: [String: Any]
    ) throws -> URLRequest {
        try URLEncoding.queryString.encode(request, with: parameters)
    }
}

// MARK: - Error Response (로깅용)

private struct APIErrorResponse: Codable {
    let message: String?
    let error: ErrorBody?

    struct ErrorBody: Codable {
        let code: String?
    }
}

// MARK: - MoyaAdapterError

enum MoyaAdapterError: Error {
    case unsupportedTask(Moya.Task)
    case streamReadFailed
    case multipartBodyWriteFailed
}

// MARK: - UploadProgressDelegate

/// 요청 바디 전송량을 Progress에 반영한다. 세션의 델리게이트 큐에서 호출되므로 격리에서 제외한다
private nonisolated final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    private let progress: Progress

    init(progress: Progress) {
        self.progress = progress
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        progress.totalUnitCount = totalBytesExpectedToSend
        progress.completedUnitCount = totalBytesSent
    }
}

// MARK: - AnyEncodable

fileprivate struct AnyEncodable: Encodable {
    /// 실제 인코딩 로직을 클로저로 저장
    private let _encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        let wrappedValue = wrapped
        _encode = { encoder in
            try wrappedValue.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
