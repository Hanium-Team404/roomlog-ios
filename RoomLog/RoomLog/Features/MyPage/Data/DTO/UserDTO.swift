//
//  UserDTO.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation

struct UserResponseDTO: Codable {
    let userId: Int
    let nickname: String
    let email: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case email
        case createdAt = "created_at"
    }

    func toDomain() -> User {
        User(
            id: userId,
            nickname: nickname,
            email: email,
            createdAt: Date.fromServerDateTime(createdAt) ?? Date()
        )
    }
}
