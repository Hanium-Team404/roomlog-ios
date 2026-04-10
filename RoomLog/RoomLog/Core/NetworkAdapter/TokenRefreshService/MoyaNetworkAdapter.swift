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
    
    /// Moya API를 요청하고 Response를 반환합니다.
    func request<T: TargetType>(_ target: T) async throws -> Moya.Response {
        // Moya TargetType을 URLRequest로 변환
        let urlRequest = try buildURLRequest(target)
        
        do {
            // NetworkClient(토큰 자동 갱신 지원)를 통해 요청
            let (data, httpResponse) = try await networkClient.request(urlRequest)
            
            // Moya의 Response 형태로 포장해서 반환
            let response = Response(
                statusCode: httpResponse.statusCode,
                data: data,
                request: urlRequest,
                response: httpResponse
            )
            return response
        } catch {
            throw error
        }
    }
}

extension MoyaNetworkAdapter {
    
    private func buildURLRequest<T: TargetType>(_ target: T) throws -> URLRequest {
        // 1. URL 구성 (baseURL + path)
        let url = target.baseURL.appending(path: target.path)

        // 2. URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue

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
            request.httpBody = try Data(contentsOf: fileURL)

        case .uploadMultipart(let multipartData):
            let (body, boundary) = try buildMultipartBody(multipartData)
            request.httpBody = body
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        case .uploadCompositeMultipart(let multipartData, let urlParameters):
            let (body, boundary) = try buildMultipartBody(multipartData)
            request.httpBody = body
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request = try encodeURLParameters(request, parameters: urlParameters)

        case .downloadDestination, .downloadParameters:
            throw MoyaAdapterError.unsupportedTask(target.task)
        }

        return request
    }
    
    private func buildMultipartBody(_ parts: [Moya.MultipartFormData]) throws -> (Data, String) {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let crlf = "\r\n"

        for part in parts {
            body.append("--\(boundary)\(crlf)".data(using: .utf8)!)

            var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let fileName = part.fileName {
                disposition += "; filename=\"\(fileName)\""
            }
            body.append("\(disposition)\(crlf)".data(using: .utf8)!)

            if let mimeType = part.mimeType {
                body.append("Content-Type: \(mimeType)\(crlf)".data(using: .utf8)!)
            }

            body.append(crlf.data(using: .utf8)!)

            switch part.provider {
            case .data(let data):
                body.append(data)
            case .file(let fileURL):
                body.append(try Data(contentsOf: fileURL))
            case .stream(let stream, let length):
                let bufferSize = 65536
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                var streamData = Data(capacity: Int(length))
                stream.open()
                defer { stream.close() }
                while stream.hasBytesAvailable {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read < 0 { throw MoyaAdapterError.streamReadFailed }
                    if read == 0 { break }
                    streamData.append(buffer, count: read)
                }
                body.append(streamData)
            }

            body.append(crlf.data(using: .utf8)!)
        }

        body.append("--\(boundary)--\(crlf)".data(using: .utf8)!)
        return (body, boundary)
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

// MARK: - MoyaAdapterError

enum MoyaAdapterError: Error {
    case unsupportedTask(Moya.Task)
    case streamReadFailed
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
