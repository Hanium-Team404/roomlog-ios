//
//  AuthUser.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

struct AuthUser {
    let userId: Int
    let email: String
    let nickname: String
}

struct SignedUpUser {
    let userId: Int
    let email: String
    let nickname: String
    let createdAt: Date
}
