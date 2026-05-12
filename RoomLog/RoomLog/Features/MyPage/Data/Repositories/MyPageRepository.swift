//
//  MyPageRepository.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation
import Moya

final class MyPageRepository: MyPageRepositoryProtocol {
    // MARK: - Property
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function
    func getUser() async throws -> User {
        let response = try await adapter.request(UserTarget.getUser)
        do {
            let dto = try decoder.decode(APIResponse<UserResponseDTO>.self, from: response.data)
            return try dto.unwrap().toDomain()
        } catch let error as DecodingError {
            throw RepositoryError.decodingError(detail: String(describing: error))
        }
    }

    func updateUser(nickname: String) async throws {
        let request = UpdateUserRequestDTO(nickname: nickname)
        let response = try await adapter.request(UserTarget.updateUser(request: request))
        let dto = try decoder.decode(APIResponse<UpdateUserResponseDTO>.self, from: response.data)
        _ = try dto.unwrap()
    }

    func deleteUser() async throws {
        let response = try await adapter.request(UserTarget.deleteUser)
        let dto = try decoder.decode(APIResponse<DeleteUserResponseDTO>.self, from: response.data)
        _ = try dto.unwrap()
    }
}
