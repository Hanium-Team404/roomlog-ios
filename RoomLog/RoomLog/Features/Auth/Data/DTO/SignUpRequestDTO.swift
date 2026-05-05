//
//  SignUpRequestDTO.swift
//  RoomLog
//
//  Created by 김도연 on 5/1/26.
//

import Foundation

struct SignUpRequestDTO: Encodable {
    let email: String
    let password: String
    let nickname: String
}
