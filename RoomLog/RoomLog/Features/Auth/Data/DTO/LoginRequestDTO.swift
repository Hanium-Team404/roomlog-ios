//
//  LoginRequestDTO.swift
//  RoomLog
//
//  Created by 김도연 on 5/1/26.
//

import Foundation

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}
