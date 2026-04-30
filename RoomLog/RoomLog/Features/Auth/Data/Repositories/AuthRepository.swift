//
//  AuthRepository.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation
import Moya

final class AuthRepository: AuthRepositoryProtocol {
    // MARK: - Property
    private let adapter: MoyaNetworkAdapter
    private let tokenStore: TokenStore
    private let decoder: JSONDecoder

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter, tokenStore: TokenStore, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.tokenStore = tokenStore
        self.decoder = decoder
    }

    // MARK: - Function
    func login(email: String, password: String) async throws -> AuthUser {
        let request = LoginRequestDTO(email: email, password: password)
        let response = try await adapter.request(AuthTarget.login(request: request))
        let dto = try decoder.decode(APIResponse<LoginResponseDTO>.self, from: response.data)
        let result = try dto.unwrap()

        try await tokenStore.save(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken
        )

        return result.toDomain()
    }

    func signUp(email: String, password: String, nickname: String) async throws -> SignedUpUser {
        let request = SignUpRequestDTO(email: email, password: password, nickname: nickname)
        let response = try await adapter.request(AuthTarget.signup(request: request))
        let dto = try decoder.decode(APIResponse<SignUpResponseDTO>.self, from: response.data)
        return try dto.unwrap().toDomain()
    }
}
