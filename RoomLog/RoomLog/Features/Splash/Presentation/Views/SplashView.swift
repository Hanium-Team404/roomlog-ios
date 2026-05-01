//
//  SplashView.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import SwiftUI

struct SplashView: View {

    @State private var viewModel: SplashViewModel
    @Environment(\.appFlow) private var appFlow

    init(
        networkClient: NetworkClient,
        getUserUseCase: GetUserUseCaseProtocol,
        tokenStore: TokenStore
    ) {
        self._viewModel = .init(
            wrappedValue: SplashViewModel(
                networkClient: networkClient,
                getUserUseCase: getUserUseCase,
                tokenStore: tokenStore
            )
        )
    }

    var body: some View {
        splash
            .task {
                await viewModel.checkAuth()
            }
            .onChange(of: viewModel.isChecked) { _, newValue in
                guard newValue else { return }
                if viewModel.isLoggedin {
                    appFlow.showMain()
                } else {
                    appFlow.showLogin()
                }
            }
    }

    var splash: some View {
        ZStack(alignment: .center) {
            Image(.splash)
                .resizable()
            Image(.logo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
        }
        .ignoresSafeArea()
    }
}
