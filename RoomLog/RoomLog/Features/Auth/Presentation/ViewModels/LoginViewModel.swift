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
    /// 로그인 성공한 계정. 값이 생기면 뷰가 메인으로 전환한다
    private(set) var loggedInUserId: Int?
    /// 이메일·비밀번호가 모두 입력됐는지. 로그인 버튼 활성화 기준
    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
            loggedInUserId = user.userId
        } catch {
            #if DEBUG
            print("❌ [Login] error: \(error)")
            #endif
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
