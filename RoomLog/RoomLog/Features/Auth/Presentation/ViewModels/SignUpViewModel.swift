//
//  SignUpViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import Foundation

@Observable
final class SignUpViewModel {
    // MARK: - Input
    var email: String = ""
    var password: String = ""
    var nickname: String = ""

    // MARK: - State
    var isLoading: Bool = false
    var errorMessage: String?
    var isSignUpCompleted: Bool = false

    // MARK: - Dependencies
    private let signUpUseCase: SignUpUseCaseProtocol

    init(signUpUseCase: SignUpUseCaseProtocol) {
        self.signUpUseCase = signUpUseCase
    }

    // MARK: - Actions
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !nickname.isEmpty
    }

    func signUp() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await signUpUseCase.execute(
                email: email,
                password: password,
                nickname: nickname
            )
            isSignUpCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
