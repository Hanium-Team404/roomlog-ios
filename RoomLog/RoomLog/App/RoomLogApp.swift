//
//  RoomLogApp.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import SwiftUI
import KakaoMapsSDK
import UserNotifications

@main
struct RoomLogApp: App {

    // MARK: - Properties
    @State private var container: DIContainer
    @State private var router: AppRouter
    /// 알림 센터가 delegate를 약하게 잡으므로 앱이 소유한다
    @State private var notificationDelegate: AppNotificationDelegate

    init() {
        SDKInitializer.InitSDK(appKey: Config.kakaoNativeAppKey)
        let container = DIContainer.configured()
        _container = State(initialValue: container)
        _router = State(initialValue: AppRouter(container: container))

        // 로그아웃 시 DI 캐시가 비워지므로 PathStore는 탭 시점에 꺼낸다
        let notificationDelegate = AppNotificationDelegate { houseId in
            container.resolve(PathStore.self).scanStatusRequest = houseId
        }
        UNUserNotificationCenter.current().delegate = notificationDelegate
        _notificationDelegate = State(initialValue: notificationDelegate)
    }


    var body: some Scene {
        WindowGroup {
            rootView
                .environment(\.di, container)
                .environment(router)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        VStack {
            switch router.state {
            case .splash:
                let getUserUseCase = container.resolve(MyPageUseCaseProvider.self).makeGetUserUseCase()
                SplashView(
                    checkSessionUseCase: CheckSessionUseCase { try await getUserUseCase.execute().id }
                )
            case .login:
                LoginView(
                    loginUseCase: container.resolve(AuthUseCaseProvider.self).loginUseCase
                )
            case .main:
                RoomLogTab()
            }
        }
        .animation(.easeOut(duration: 0.2), value: router.state)
    }
}
