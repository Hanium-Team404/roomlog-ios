//
//  AuthRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

protocol AuthRepositoryProtocol {
    func login(body: LoginRequestDTO) async throws -> AuthUser
    func signUp(body: SignUpRequestDTO) async throws -> SignedUpUser
}
