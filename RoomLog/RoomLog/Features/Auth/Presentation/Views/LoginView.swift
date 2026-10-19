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
            ScrollView {
                VStack(spacing: 0) {
                    logoSection
                    inputFields
                    loginButton
                    signUpLink
                }
            }
            .defaultScrollAnchor(.center, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
        }
        .onChange(of: viewModel.loggedInUserId) { _, userId in
            guard let userId else { return }
            router.completeLogin(userId: userId)
        }
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
            VStack(alignment: .leading, spacing: 6) {
                TextField("이메일", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(.neutral50, in: Capsule())
                    .font(.medium, 16)

                if let emailError = viewModel.emailError {
                    InlineErrorText(message: emailError)
                }
            }

            SecureField("비밀번호", text: $viewModel.password)
                .textContentType(.password)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(.neutral50, in: Capsule())
                .font(.medium, 16)

            if let errorMessage = viewModel.errorMessage {
                InlineErrorText(message: errorMessage)
            }
        }
        // CTA 버튼의 좌우 여백(16)과 폭을 맞춘다
        .padding(.horizontal, 16)
    }

    var loginButton: some View {
        BottomCTAButton {
            Task { await viewModel.login() }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("로그인")
                    .font(.semibold, 16)
            }
        }
        // 입력이 비어 있으면 눌러도 에러 문구만 뜨므로 처음부터 비활성화한다
        .disabled(viewModel.isLoading || !viewModel.canSubmit)
        .padding(.top, 24)
    }

    // BottomCTAButton이 아래 여백(16)을 포함하므로 링크 쪽 위 여백은 두지 않는다
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
    }
}
