//
//  SignUpResponseDTO.swift
//  RoomLog
//
//  Created by 김도연 on 5/1/26.
//

import Foundation

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
