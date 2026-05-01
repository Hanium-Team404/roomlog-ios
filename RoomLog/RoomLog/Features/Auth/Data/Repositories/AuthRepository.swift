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
    func login(
        body: LoginRequestDTO
    ) async throws -> AuthUser {
        let response = try await adapter.request(AuthTarget.login(request: body))
        do {
            let dto = try decoder.decode(APIResponse<LoginResponseDTO>.self, from: response.data)
            return try dto.unwrap().toDomain()
        } catch let error as DecodingError {
            throw RepositoryError.decodingError(detail: String(describing: error))
        }
    }

    func signUp(body: SignUpRequestDTO) async throws -> SignedUpUser {
        let response = try await adapter.request(AuthTarget.signup(request: body))
        do {
            let dto = try decoder.decode(APIResponse<SignUpResponseDTO>.self, from: response.data)
            return try dto.unwrap().toDomain()
        } catch let error as DecodingError {
            throw RepositoryError.decodingError(detail: String(describing: error))
        }
    }
}
