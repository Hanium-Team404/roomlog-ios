//
//  LoginResponseDTO.swift
//  RoomLog
//
//  Created by 김도연 on 5/1/26.
//

import Foundation

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
            nickname: nickname,
            tokenPair: TokenPair(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        )
    }
}
