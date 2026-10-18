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
    var nickname: String = "" {
        didSet { if nickname != oldValue { errorMessage = nil } }
    }

    // MARK: - State
    var isLoading: Bool = false
    /// 이메일 필드 바로 아래에 표시할 안내 (형식 오류·중복 이메일)
    private(set) var emailError: String?
    /// 특정 필드에 귀속되지 않는 실패 안내 (연결 실패·서버 오류 등)
    var errorMessage: String?
    var isSignUpCompleted: Bool = false
    /// 이메일 형식이 맞고 비밀번호·닉네임이 모두 입력됐는지. 회원가입 버튼 활성화 기준
    var canSubmit: Bool {
        Self.isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines))
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 입력이 멈춘 뒤 형식 검사를 실행하는 디바운스 Task. 테스트는 이 값을 await해 결과를 확인한다
    @ObservationIgnored private(set) var emailValidationTask: Task<Void, Never>?
    /// 마지막 입력 후 형식 검사까지 기다리는 시간
    private static let validationDebounce: Duration = .milliseconds(300)

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
        emailError = nil
        errorMessage = nil

        do {
            _ = try await signUpUseCase.execute(
                email: trimmedEmail,
                password: trimmedPassword,
                nickname: trimmedNickname
            )
            isSignUpCompleted = true
        } catch {
            let repositoryError = RepositoryError.normalize(error)
            if repositoryError.serverErrorCode == .authDuplicateEmail {
                // 서버가 알려준 중복은 이메일 필드의 문제이므로 그 자리에서 안내한다
                emailError = "이미 가입된 이메일입니다. 다른 이메일을 입력해 주세요."
            } else {
                errorMessage = repositoryError.userMessage
            }
        }

        isLoading = false
    }

    // MARK: - Validation

    /// 매 글자마다 지적하면 거슬리므로, 입력이 멈추고 debounce 시간이 지난 뒤 한 번만 검사한다.
    /// 그 사이 다시 입력하면 이전 예약은 취소된다
    private func scheduleEmailValidation() {
        emailValidationTask?.cancel()
        emailValidationTask = Task { [weak self] in
            try? await Task.sleep(for: Self.validationDebounce)
            guard !Task.isCancelled else { return }
            self?.validateEmailFormat()
        }
    }

    /// 비어 있으면 아직 입력 전이므로 지적하지 않는다
    func validateEmailFormat() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !Self.isValidEmail(trimmedEmail) else { return }
        emailError = "올바른 이메일 형식을 입력해 주세요."
    }

    /// `로컬@도메인.최상위` 꼴인지 확인한다. 실제 존재 여부는 서버가 판단하므로 공백·@ 누락 같은 오타만 거른다
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
