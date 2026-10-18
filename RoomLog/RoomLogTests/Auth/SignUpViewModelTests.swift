//
//  SignUpViewModelTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/18/26.
//

import Foundation
import Testing
@testable import RoomLog

@MainActor
struct SignUpViewModelTests {

    private final class MockSignUpUseCase: SignUpUseCaseProtocol {
        var result: Result<SignedUpUser, Error>
        private(set) var callCount = 0

        init(result: Result<SignedUpUser, Error>) {
            self.result = result
        }

        func execute(email: String, password: String, nickname: String) async throws -> SignedUpUser {
            callCount += 1
            return try result.get()
        }
    }

    // 기본 인자에서 참조하므로 격리 없이 둔다
    nonisolated private static let signedUp = SignedUpUser(userId: 1, email: "dy@test.com", nickname: "도연", createdAt: Date())

    private func makeSUT(
        result: Result<SignedUpUser, Error> = .success(signedUp),
        email: String = "dy@test.com"
    ) -> (SignUpViewModel, MockSignUpUseCase) {
        let useCase = MockSignUpUseCase(result: result)
        // 디바운스 결과는 벽시계 대기 대신 emailValidationTask를 await해 확인한다
        let sut = SignUpViewModel(signUpUseCase: useCase)
        sut.email = email
        sut.password = "password"
        sut.nickname = "도연"
        return (sut, useCase)
    }

    // MARK: - 이메일 형식

    @Test("올바른 형식은 통과한다", arguments: ["dy@test.com", "a.b+c@sub.example.co.kr"])
    func isValidEmail_acceptsWellFormed(email: String) {
        #expect(SignUpViewModel.isValidEmail(email))
    }

    @Test("이메일 형식이 틀리면 회원가입 버튼이 비활성화된다", arguments: [
        "dy", "dy@", "@test.com", "dy@test", "dy test@test.com", "dy@test.c",
    ])
    func canSubmit_invalidEmail_isFalse(email: String) {
        let (sut, _) = makeSUT(email: email)

        #expect(sut.canSubmit == false)
    }

    @Test("모든 입력이 올바르면 회원가입 버튼이 활성화된다")
    func canSubmit_allValid_isTrue() {
        let (sut, _) = makeSUT()

        #expect(sut.canSubmit)
    }

    @Test("입력이 멈춘 뒤 잘못된 형식이면 필드 오류를 보여준다")
    func debouncedValidation_invalid_showsFieldError() async {
        let (sut, _) = makeSUT(email: "dy@test")

        await sut.emailValidationTask?.value

        #expect(sut.emailError == "올바른 이메일 형식을 입력해 주세요.")
    }

    @Test("입력이 멈춘 뒤 비어 있거나 올바르면 지적하지 않는다", arguments: ["", "   ", "dy@test.com"])
    func debouncedValidation_emptyOrValid_noError(email: String) async {
        let (sut, _) = makeSUT(email: email)

        await sut.emailValidationTask?.value

        #expect(sut.emailError == nil)
    }

    @Test("입력이 이어지면 이전 검사 예약은 취소되고 마지막 값만 검사한다")
    func debouncedValidation_cancelsPreviousSchedule() async {
        let (sut, _) = makeSUT(email: "dy")
        let firstTask = sut.emailValidationTask

        sut.email = "dy@test.com"
        await firstTask?.value
        await sut.emailValidationTask?.value

        #expect(firstTask?.isCancelled == true)
        #expect(sut.emailError == nil)
    }

    // MARK: - 서버 결과 구분

    @Test("중복 이메일은 이메일 필드 오류로 안내한다")
    func signUp_duplicateEmail_showsFieldError() async {
        let (sut, _) = makeSUT(result: .failure(
            RepositoryError.serverError(code: 409, message: nil, errorCode: .authDuplicateEmail)
        ))

        await sut.signUp()

        #expect(sut.emailError == "이미 가입된 이메일입니다. 다른 이메일을 입력해 주세요.")
        #expect(sut.errorMessage == nil)
        #expect(sut.isSignUpCompleted == false)
    }

    @Test("그 외 실패는 일반 오류 문구로 안내한다")
    func signUp_otherFailure_showsGeneralMessage() async {
        let (sut, _) = makeSUT(result: .failure(URLError(.timedOut)))

        await sut.signUp()

        #expect(sut.emailError == nil)
        #expect(sut.errorMessage == RepositoryError.transportError(code: .timedOut).userMessage)
    }

    // MARK: - 오류 갱신

    @Test("이메일을 수정하면 이메일 오류가 즉시 사라진다")
    func editingEmail_clearsEmailError() async throws {
        let (sut, _) = makeSUT(email: "dy")
        await sut.emailValidationTask?.value
        try #require(sut.emailError != nil)

        sut.email = "dy@"

        #expect(sut.emailError == nil)
    }

    @Test("성공하면 완료 상태가 된다")
    func signUp_success_marksCompleted() async {
        let (sut, _) = makeSUT()

        await sut.signUp()

        #expect(sut.isSignUpCompleted)
        #expect(sut.emailError == nil)
        #expect(sut.errorMessage == nil)
    }
}
