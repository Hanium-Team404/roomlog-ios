//
//  SplashViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation
import Observation

@Observable
final class SplashViewModel {

    /// 세션 확인 결과. 확인 중과 확인 완료를 한 값으로 구분하고, 로그인 상태에는 반드시 사용자 ID가 함께 있다
    enum SessionState: Equatable {
        case checking
        case loggedIn(userId: Int)
        case loggedOut
    }

    private let checkSessionUseCase: CheckSessionUseCaseProtocol
    /// 스플래시 최소 노출 시간. 세션 확인이 먼저 끝나도 이 시간은 기다린다
    private let minimumDisplayDuration: Duration

    private(set) var sessionState: SessionState = .checking

    init(
        checkSessionUseCase: CheckSessionUseCaseProtocol,
        minimumDisplayDuration: Duration = .seconds(2)
    ) {
        self.checkSessionUseCase = checkSessionUseCase
        self.minimumDisplayDuration = minimumDisplayDuration
    }

    @MainActor
    func checkAuth() async {
        async let delay = Task.sleep(for: minimumDisplayDuration)

        let result: SessionState
        do {
            let userId = try await checkSessionUseCase.execute()
            result = .loggedIn(userId: userId)
        } catch {
            result = .loggedOut
        }

        _ = try? await delay

        sessionState = result
    }
}
