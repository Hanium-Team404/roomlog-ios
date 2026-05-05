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
    
    @MainActor
    func signUp() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty, !trimmedNickname.isEmpty else {
            errorMessage = "이메일, 비밀번호와 닉네임을 입력해주세요."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await signUpUseCase.execute(
                email: trimmedEmail,
                password: trimmedPassword,
                nickname: trimmedNickname
            )
            isSignUpCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
