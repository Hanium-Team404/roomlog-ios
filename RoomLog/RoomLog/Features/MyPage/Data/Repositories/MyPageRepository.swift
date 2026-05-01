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
        let dto = try decoder.decode(APIResponse<UserResponseDTO>.self, from: response.data)
        print(dto)
        return try dto.unwrap().toDomain()
    }
}
