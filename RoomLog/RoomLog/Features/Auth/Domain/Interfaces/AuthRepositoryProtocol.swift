//
//  AuthRepositoryProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String, nickname: String) async throws -> SignedUpUser
}
