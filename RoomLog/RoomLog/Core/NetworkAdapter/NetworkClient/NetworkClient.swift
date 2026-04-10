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
    /// 인증 정책 (요청 별로 인증이 필요한 지 판단
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
    func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await performRequest(urlRequest, retryCount: 0)
    }
    
    /// 강제로 토큰을 갱신
    func forceRefreshToken() async throws -> TokenPair {
        try await refreshToken(force: true)
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
    private func performRequest(_ urlRequest: URLRequest, retryCount: Int) async throws -> (Data, HTTPURLResponse) {
        var authenticatedRequest = urlRequest
        
        // 인증 필요 여부 확인
        if authPolicy.requireAuthentication(urlRequest) {
            if let token = await tokenStore.getAccessToken() {
                authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // 네트워크 요청 실행
        let (data, response) = try await session.data(for: authenticatedRequest)
        
        // HTTPURLResponse로 변환
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // 401 에러 응답 처리
        if authPolicy.isUnauthorizedResponse(httpResponse) {
            guard retryCount < maxRetryCount else {
                throw NetworkError.unauthorized
            }

            _ = try await refreshToken(force: true)

            return try await performRequest(urlRequest, retryCount: retryCount + 1)
        }

        // 성공 응답 확인
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return (data, httpResponse)
    }
    
    /// 토큰 갱신 수행
    private func refreshToken(force: Bool = false) async throws -> TokenPair {
        // 토큰 갱신 중인지 Task 확인
        if let existTask = refreshTask {
            // 기존 Task의 결과를 대기하여 변환
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
            
            do {
                // Token 갱신 요청
                let tokenPair = try await refreshService.refresh(refreshToken)
                // 새 TokenPair 저장
                try await tokenStore.save(
                    accessToken: tokenPair.accessToken,
                    refreshToken: tokenPair.refreshToken
                )
                
                return tokenPair
            } catch {
                throw error
            }
        }
        // refreshTask에 Task 저장 (다른 요청이 대기할 수 있도록)
        refreshTask = task
        return try await task.value
    }
}

