//
//  RoomLogApp.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import SwiftUI
import KakaoMapsSDK

@main
struct RoomLogApp: App {

    //MARK: - Properties
    @State private var container: DIContainer
    @State private var router: AppRouter
    /// App 계층에서 읽으면 모든 씬을 합친 상태가 된다.
    /// `ScanProcessingManager`는 DI 싱글톤(앱당 1개)이므로 신호도 앱 전역이어야 맞다 —
    /// 하위 View에서 읽으면 그 View가 속한 씬 하나의 상태만 반영한다.
    @Environment(\.scenePhase) private var scenePhase

    init() {
        SDKInitializer.InitSDK(appKey: Config.kakaoNativeAppKey)
        let container = DIContainer.configured()
        _container = State(initialValue: container)
        _router = State(initialValue: AppRouter(container: container))
    }


    var body: some Scene {
        WindowGroup {
            rootView
                .environment(\.di, container)
                .environment(router)
        }
        .onChange(of: scenePhase) { _, newPhase in
            container.resolve(ScanProcessingManager.self).handleScenePhase(newPhase)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        VStack {
            switch router.state {
            case .splash:
                SplashView(
                    networkClient: container.resolve(NetworkClient.self),
                    getUserUseCase: container.resolve(MyPageUseCaseProvider.self).makeGetUserUseCase(),
                    tokenStore: container.resolve(TokenStore.self)
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
