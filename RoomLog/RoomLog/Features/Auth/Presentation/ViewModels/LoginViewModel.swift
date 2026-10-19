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
    // 입력을 고치기 시작하면 직전 실패 안내는 더 이상 유효하지 않으므로 지운다
    var email: String = "" {
        didSet {
            guard email != oldValue else { return }
            emailError = nil
            errorMessage = nil
            scheduleEmailValidation()
        }
    }
    var password: String = "" {
        didSet { if password != oldValue { errorMessage = nil } }
    }

    // MARK: - State
    private(set) var isLoading: Bool = false
    private(set) var emailError: String?
    private(set) var errorMessage: String?
    /// 로그인 성공한 계정. 값이 생기면 뷰가 메인으로 전환한다
    private(set) var loggedInUserId: Int?
    /// 이메일 형식이 맞고 비밀번호가 입력됐는지. 로그인 버튼 활성화 기준
    var canSubmit: Bool {
        SignUpViewModel.isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines))
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ObservationIgnored private(set) var emailValidationTask: Task<Void, Never>?
    private static let validationDebounce: Duration = .milliseconds(300)

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
            errorMessage = "이메일과 비밀번호를 입력해 주세요."
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
            // 자격 증명 오류(AUTH_001)·연결 실패·서버 오류 문구는 Core/Error의 코드별 테이블이 구분한다.
            // 토큰 저장 실패 등 Repository 밖 오류가 섞일 수 있어 한 번 더 정규화한다
            errorMessage = RepositoryError.normalize(error).userMessage
        }

        isLoading = false
    }

    // MARK: - Validation

    private func scheduleEmailValidation() {
        emailValidationTask?.cancel()
        emailValidationTask = Task { [weak self] in
            try? await Task.sleep(for: Self.validationDebounce)
            guard !Task.isCancelled else { return }
            self?.validateEmailFormat()
        }
    }

    func validateEmailFormat() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !SignUpViewModel.isValidEmail(trimmedEmail) else { return }
        emailError = "올바른 이메일 형식을 입력해 주세요."
    }
}
