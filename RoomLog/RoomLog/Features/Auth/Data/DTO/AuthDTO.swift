//
//  AuthDTO.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

// MARK: - Request DTO

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}

struct SignUpRequestDTO: Encodable {
    let email: String
    let password: String
    let nickname: String
}

// MARK: - Response DTO

struct LoginResponseDTO: Codable {
    let userId: Int
    let email: String
    let nickname: String
    let accessToken: String
    let refreshToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nickname
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }

    func toDomain() -> AuthUser {
        AuthUser(
            userId: userId,
            email: email,
            nickname: nickname
        )
    }
}

struct SignUpResponseDTO: Codable {
    let userId: Int
    let email: String
    let nickname: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nickname
        case createdAt = "created_at"
    }

    func toDomain() -> SignedUpUser {
        SignedUpUser(
            userId: userId,
            email: email,
            nickname: nickname,
            createdAt: Date.fromServerDateTime(createdAt) ?? Date()
        )
    }
}
