//
//  AppRouter.swift
//  RoomLog
//
//  Created by 김도연 on 7/5/26.
//

import SwiftUI

/// 앱 루트 화면(splash/login/main) 전환을 담당하는 라우터.
/// 환경에 클로저를 저장하던 기존 `AppFlow`를 대체하며, `@Observable`의
/// 프로퍼티 단위 추적으로 `state`를 읽는 뷰만 갱신되도록 한다.
@Observable
final class AppRouter {

    enum AppState: Equatable {
        case splash
        case login
        case main
    }

    private(set) var state: AppState = .splash

    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
    }

    func showLogin() {
        transition(to: .login)
    }

    func showMain() {
        transition(to: .main)
    }

    func logout() {
        Task {
            try? await container.resolve(NetworkClient.self).logout()
        }
        container.resetCache()
        transition(to: .login)
    }

    private func transition(to newState: AppState) {
        guard newState != state else { return }
        withAnimation {
            state = newState
        }
    }
}
