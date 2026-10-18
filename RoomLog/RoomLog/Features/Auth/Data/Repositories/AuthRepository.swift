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
    private let decoder: JSONDecoder

    // MARK: - Init
    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function
    // 실패는 requestDecoded에서 전부 RepositoryError로 정규화되므로 호출자는 userMessage만 쓰면 된다
    func login(body: LoginRequestDTO) async throws -> AuthUser {
        let dto: LoginResponseDTO = try await adapter.requestDecoded(AuthTarget.login(request: body), decoder: decoder)
        return dto.toDomain()
    }

    func signUp(body: SignUpRequestDTO) async throws -> SignedUpUser {
        let dto: SignUpResponseDTO = try await adapter.requestDecoded(AuthTarget.signup(request: body), decoder: decoder)
        return dto.toDomain()
    }
}
