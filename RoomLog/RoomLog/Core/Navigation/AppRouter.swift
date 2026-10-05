//
//  AppRouter.swift
//  RoomLog
//
//  Created by 김도연 on 7/5/26.
//

import SwiftUI
import UserNotifications

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
    private let lastLoginStore: LastLoginStore

    init(container: DIContainer, lastLoginStore: LastLoginStore = LastLoginStore()) {
        self.container = container
        self.lastLoginStore = lastLoginStore
    }

    func showLogin() {
        transition(to: .login)
    }

    func showMain() {
        transition(to: .main)
    }

    /// 로그인 성공 후 메인 진입.
    /// 세션 만료 시 Splash가 `logout()`을 거치지 않고 로그인 화면으로 보내므로 이전 계정의 스캔 기록·완료 알림이 남아 있을 수 있다.
    /// 다른 계정이면 메인 진입(= 스캔 매니저 생성·복원) 전에 정리하고, 같은 계정이면 진행 중인 스캔을 이어간다
    func completeLogin(userId: Int) {
        if lastLoginStore.recordLogin(userId: userId) {
            discardPreviousAccountScan()
        }
        showMain()
    }

    func logout() {
        // 재로그인 후엔 진행 중이던 스캔을 이어받을 경로가 없으므로 서버 스캔까지 취소한다.
        // 인증된 취소 요청이 나가도록 토큰 삭제는 취소 요청이 끝난 뒤에 한다
        let scanCancellation = container.resolve(ScanProcessingManager.self).cancel()
        Task {
            await scanCancellation?.value
            try? await container.resolve(NetworkClient.self).logout()
        }
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        container.resetCache()
        transition(to: .login)
    }

    /// 이전 계정의 스캔 기록·zip, 완료 알림, 알림 탭으로 남은 스캔 상태 시트 요청을 지운다.
    /// 남은 데이터셋 폴더는 매니저 생성 시 `sweepOrphans()`가 정리한다
    private func discardPreviousAccountScan() {
        ScanArtifactStore().clear()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        container.resolve(PathStore.self).scanStatusRequest = nil
    }

    private func transition(to newState: AppState) {
        guard newState != state else { return }
        state = newState
    }
}
