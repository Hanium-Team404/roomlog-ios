//
//  LoginView.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import SwiftUI

struct LoginView: View {

    @State private var viewModel: LoginViewModel
    @Environment(AppRouter.self) private var router

    init(
        loginUseCase: LoginUseCaseProtocol
    ) {
        self._viewModel = .init(
            wrappedValue: LoginViewModel(loginUseCase: loginUseCase)
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                logoSection
                inputFields
                errorMessage
                loginButton
                signUpLink
                Spacer()
            }
        }
        .onChange(of: viewModel.loginState) { _, newValue in
            switch newValue {
            case true:
                router.showMain()
            case false:
                router.showLogin()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Subviews
private extension LoginView {

    var logoSection: some View {
        Image(.logo)
            .resizable()
            .scaledToFit()
            .frame(width: 120)
            .padding(.bottom, 48)
    }

    var inputFields: some View {
        VStack(spacing: 16) {
            TextField("이메일", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(16)
                .background(.neutral50, in: RoundedRectangle(cornerRadius: 12))
                .font(.medium, 16)

            SecureField("비밀번호", text: $viewModel.password)
                .textContentType(.password)
                .padding(16)
                .background(.neutral50, in: RoundedRectangle(cornerRadius: 12))
                .font(.medium, 16)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    var errorMessage: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .font(.regular, 14)
                .padding(.top, 12)
                .padding(.horizontal, 24)
        }
    }

    var loginButton: some View {
        Button {
            Task { await viewModel.login() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("로그인")
                        .font(.semibold, 16)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(.deepNavy, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isLoading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    var signUpLink: some View {
        NavigationLink {
            SignUpView()
        } label: {
            HStack(spacing: 4) {
                Text("계정이 없으신가요?")
                    .foregroundStyle(.neutral500)
                Text("회원가입")
                    .foregroundStyle(.deepNavy)
            }
            .font(.medium, 14)
        }
        .padding(.top, 16)
    }
}
