//
//  LoginViewModelTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/18/26.
//

import Foundation
import Testing
@testable import RoomLog

@MainActor
struct LoginViewModelTests {

    private final class MockLoginUseCase: LoginUseCaseProtocol {
        var result: Result<AuthUser, Error>

        init(result: Result<AuthUser, Error>) {
            self.result = result
        }

        func execute(email: String, password: String) async throws -> AuthUser {
            try result.get()
        }
    }

    private static let user = AuthUser(
        userId: 1,
        email: "dy@test.com",
        nickname: "도연",
        tokenPair: TokenPair(accessToken: "access", refreshToken: "refresh")
    )

    private func makeSUT(result: Result<AuthUser, Error>) -> LoginViewModel {
        let sut = LoginViewModel(loginUseCase: MockLoginUseCase(result: result))
        sut.email = "dy@test.com"
        sut.password = "password"
        return sut
    }

    // MARK: - 오류 문구 구분

    @Test("자격 증명 오류는 이메일·비밀번호 확인 문구로 안내한다", .bug("https://github.com/Hanium-Team404/roomlog-ios/issues/227"))
    func login_invalidCredentials_showsCredentialMessage() async {
        let sut = makeSUT(result: .failure(
            RepositoryError.serverError(code: 401, message: nil, errorCode: .authInvalidCredentials)
        ))

        await sut.login()

        #expect(sut.errorMessage == "이메일 또는 비밀번호를 확인해 주세요.")
        #expect(sut.loggedInUserId == nil)
    }

    @Test("전송 실패는 네트워크 안내로 구분한다")
    func login_transportError_showsNetworkMessage() async {
        let sut = makeSUT(result: .failure(URLError(.notConnectedToInternet)))

        await sut.login()

        #expect(sut.errorMessage == RepositoryError.transportError(code: .notConnectedToInternet).userMessage)
    }

    @Test("서버 오류는 자격 증명 문구를 쓰지 않는다")
    func login_serverError_showsServerMessage() async {
        let error = RepositoryError.serverError(code: 500, message: nil, errorCode: .commonServerError)
        let sut = makeSUT(result: .failure(error))

        await sut.login()

        #expect(sut.errorMessage == error.userMessage)
        #expect(sut.errorMessage != "이메일 또는 비밀번호를 확인해 주세요.")
    }

    // MARK: - 오류 갱신

    @Test("입력을 수정하면 오류 안내가 사라진다")
    func editingInput_clearsErrorMessage() async throws {
        let sut = makeSUT(result: .failure(
            RepositoryError.serverError(code: 401, message: nil, errorCode: .authInvalidCredentials)
        ))
        await sut.login()
        try #require(sut.errorMessage != nil)

        sut.password = "another"

        #expect(sut.errorMessage == nil)
    }

    @Test("성공하면 로그인 사용자 ID가 설정된다")
    func login_success_setsUserId() async {
        let sut = makeSUT(result: .success(Self.user))

        await sut.login()

        #expect(sut.loggedInUserId == 1)
        #expect(sut.errorMessage == nil)
    }
}
