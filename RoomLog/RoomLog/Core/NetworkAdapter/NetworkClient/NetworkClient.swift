//
//  NetworkClient.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

actor NetworkClient {
    // MARK: - Dependencies
    /// URLSession instance (네트워크 요청 실행)
    private let session: URLSession
    /// 토큰 저장소
    private let tokenStore: TokenStore
    /// 토큰 갱신 서비스
    private let refreshService: TokenRefreshService
    /// 인증 정책 (요청별로 인증이 필요한지 판단)
    private let authPolicy: AuthenticationPolicy
    /// 401발생 시 최대 재시도 횟수
    private let maxRetryCount: Int
    /// 현재 진행 중인 토큰 갱신 Task
    private var refreshTask: Task<TokenPair, Error>?
    
    
    // MARK: - Initializer
    init(
        session: URLSession = .shared,
        tokenStore: TokenStore,
        refreshService: TokenRefreshService,
        authPolicy: AuthenticationPolicy = DefaultAuthenticationPolicy(),
        maxRetryCount: Int = 1
    ) {
        self.session = session
        self.tokenStore = tokenStore
        self.refreshService = refreshService
        self.authPolicy = authPolicy
        self.maxRetryCount = maxRetryCount
    }
    
    // MARK: - Public API Request
    
    /// API 요청을 실행하고 데이터와 HTTP 응답을 반환
    /// - Parameter delegate: 요청별 태스크 이벤트(업로드 진행률 등)를 받을 델리게이트
    func request(_ urlRequest: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, HTTPURLResponse) {
        try await performRequest(urlRequest, bodyFile: nil, retryCount: 0, delegate: delegate)
    }

    /// 요청 바디를 파일에서 바로 전송한다. 대용량 업로드를 메모리에 올리지 않기 위한 경로이며
    /// 401 재시도 시에도 같은 파일을 다시 보내므로 호출자는 요청이 끝날 때까지 파일을 유지해야 한다
    func upload(_ urlRequest: URLRequest, fromFile fileURL: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, HTTPURLResponse) {
        try await performRequest(urlRequest, bodyFile: fileURL, retryCount: 0, delegate: delegate)
    }
    
    /// 토큰 갱신을 요청한다. 진행 중인 갱신이 있으면 그 결과에 합류한다
    func forceRefreshToken() async throws -> TokenPair {
        try await refreshToken()
    }
    
    /// 로그아웃 처리를 수행
    ///
    /// 현재 진행 중인 토큰 갱신 Task 취소 및 저장된 Token 삭제
    func logout() async throws {
        refreshTask?.cancel()
        refreshTask = nil
        try await tokenStore.clear()
    }
    
    /// 로그인 여부 확인
    func isLoggedIn() async -> Bool {
        await tokenStore.getAccessToken() != nil
    }
}


// MARK: - Private Method
extension NetworkClient {
    /// 실제 네트워크 요청 수행
    ///
    /// Authentication 필요 여부에 따라 Header 조절
    private func performRequest(
        _ urlRequest: URLRequest,
        bodyFile: URL?,
        retryCount: Int,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        var authenticatedRequest = urlRequest

        // 인증 필요 여부 확인
        if authPolicy.requireAuthentication(urlRequest) {
            if let token = await tokenStore.getAccessToken() {
                authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        // 네트워크 요청 실행 (바디 파일이 있으면 파일에서 스트리밍 전송)
        let (data, response) = if let bodyFile {
            try await session.upload(for: authenticatedRequest, fromFile: bodyFile, delegate: delegate)
        } else {
            try await session.data(for: authenticatedRequest, delegate: delegate)
        }
        
        // HTTPURLResponse로 변환
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // 401 에러 응답 처리
        if authPolicy.isUnauthorizedResponse(httpResponse) {
            guard retryCount < maxRetryCount else {
                throw NetworkError.unauthorized
            }

            _ = try await refreshToken()

            return try await performRequest(urlRequest, bodyFile: bodyFile, retryCount: retryCount + 1, delegate: delegate)
        }

        // 성공 응답 확인
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return (data, httpResponse)
    }
    
    /// 토큰 갱신 수행
    private func refreshToken() async throws -> TokenPair {
        // 토큰 갱신 중인지 Task 확인
        if let existTask = refreshTask {
            // 기존 Task의 결과를 대기하여 반환
            return try await existTask.value
        }
        
        // 새 토큰 갱신 Task
        let task = Task<TokenPair, Error> {
            // Task 완료 시 refreshTask를 nil로 초기화
            defer { refreshTask = nil }
            
            // refreshToken 존재 확인
            guard let refreshToken = await tokenStore.getRefreshToken() else {
                throw NetworkError.unauthorized
            }

            // Token 갱신 요청
            let tokenPair = try await refreshService.refresh(refreshToken)
            // 응답 대기 중 logout()으로 취소됐으면 저장하지 않는다 — 지운 토큰이 되살아나지 않도록
            try Task.checkCancellation()
            // 새 TokenPair 저장
            try await tokenStore.save(
                accessToken: tokenPair.accessToken,
                refreshToken: tokenPair.refreshToken
            )

            return tokenPair
        }
        // refreshTask에 Task 저장 (다른 요청이 대기할 수 있도록)
        refreshTask = task
        return try await task.value
    }
}

