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
    var isLoading: Bool = false
    var errorMessage: String?
    var isLoggedIn: Bool = false

    // MARK: - Dependencies
    private let loginUseCase: LoginUseCaseProtocol

    init(loginUseCase: LoginUseCaseProtocol) {
        self.loginUseCase = loginUseCase
    }

    // MARK: - Actions
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    func login() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await loginUseCase.execute(email: email, password: password)
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
