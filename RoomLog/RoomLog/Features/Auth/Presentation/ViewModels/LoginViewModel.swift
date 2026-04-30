//
//  LoginViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

@Observable
final class LoginViewModel {
    // MARK: - Input
    var email: String = ""
    var password: String = ""

    // MARK: - State
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var loginState: Bool = false

    private let loginUseCase: LoginUseCaseProtocol

    // MARK: - Init
    init(loginUseCase: LoginUseCaseProtocol) {
        self.loginUseCase = loginUseCase
    }

    // MARK: - Actions
    
    @MainActor
    func login() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "이메일과 비밀번호를 입력해주세요."
            return
        }
        
        isLoading = true
        errorMessage = nil

        do {
            let user = try await loginUseCase.execute(email: trimmedEmail, password: trimmedPassword)
            #if DEBUG
            print("✅ [Login] userId: \(user.userId), email: \(user.email)")
            print("✅ [Login] accessToken: \(user.tokenPair.accessToken.prefix(20))...")
            print("✅ [Login] refreshToken: \(user.tokenPair.refreshToken.prefix(20))...")
            #endif
            loginState = true
        } catch {
            #if DEBUG
            print("❌ [Login] error: \(error)")
            #endif
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
