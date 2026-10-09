//
//  SplashViewModelTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/9/26.
//

import Testing
import Foundation
@testable import RoomLog

/// 세션 확인 결과가 라우팅에 필요한 상태(사용자 ID 포함)로 정확히 매핑되는지 검사한다
@MainActor
struct SplashViewModelTests {

    private struct StubCheckSessionUseCase: CheckSessionUseCaseProtocol {
        let result: Result<Int, Error>
        func execute() async throws -> Int { try result.get() }
    }

    private struct SessionFailure: Error {}

    @Test func 확인_전에는_checking이다() {
        let sut = SplashViewModel(
            checkSessionUseCase: StubCheckSessionUseCase(result: .success(7)),
            minimumDisplayDuration: .zero
        )

        #expect(sut.sessionState == .checking)
    }

    @Test func 세션이_유효하면_사용자_ID와_함께_loggedIn이_된다() async {
        let sut = SplashViewModel(
            checkSessionUseCase: StubCheckSessionUseCase(result: .success(7)),
            minimumDisplayDuration: .zero
        )

        await sut.checkAuth()

        #expect(sut.sessionState == .loggedIn(userId: 7))
    }

    @Test func 세션_확인에_실패하면_loggedOut이_된다() async {
        let sut = SplashViewModel(
            checkSessionUseCase: StubCheckSessionUseCase(result: .failure(SessionFailure())),
            minimumDisplayDuration: .zero
        )

        await sut.checkAuth()

        #expect(sut.sessionState == .loggedOut)
    }
}
