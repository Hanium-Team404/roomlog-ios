//
//  SignUpUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

protocol SignUpUseCaseProtocol {
    func execute(email: String, password: String, nickname: String) async throws -> SignedUpUser
}
