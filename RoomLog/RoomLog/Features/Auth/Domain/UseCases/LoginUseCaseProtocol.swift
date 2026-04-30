//
//  LoginUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

protocol LoginUseCaseProtocol {
    func execute(email: String, password: String) async throws -> AuthUser
}
