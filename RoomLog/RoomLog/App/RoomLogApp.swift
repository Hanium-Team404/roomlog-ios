//
//  RoomLogApp.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import SwiftUI

@main
struct RoomLogApp: App {
    
    //MARK: - Properties
    @State private var container: DIContainer
    @State private var appState: AppState = .login //TODO: SplashView 제작 이후 앱 진입점 .splash로 변경
    
    init() {
        _container = State(
            initialValue: DIContainer.configured()
        )
    }
    
    
    var body: some Scene {
        WindowGroup {
            rootView
                .environment(\.di, container)
                .environment(\.appFlow, appFlow)
        }
    }
    
    @ViewBuilder
    private var rootView: some View {
        VStack {
            switch appState {
            case .splash:
                Text("roomlog_splashview")
            case .login:
                LoginView(
                    loginUseCase: container.resolve(AuthUseCaseProvider.self).loginUseCase
                )
            case .main:
                RoomLogTab()
            }
        }
        .animation(.easeOut(duration: 0.2), value: appState)
    }
    
    private enum AppState: Equatable {
        
        case splash
        
        case login
        
        case main
    }
    
    private var appFlow: AppFlow {
        AppFlow(
            showLogin: { transition(to: .login) },
            showMain: { transition(to: .main) },
            logout: {
                Task {
                    try? await container.resolve(NetworkClient.self).logout()
                }
                container.resetCache()
                transition(to: .login)
            }
        )
    }
    
    private func transition(to state: AppState) {
        guard state != appState else { return }
        withAnimation {
            appState = state
        }
    }
}
