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
