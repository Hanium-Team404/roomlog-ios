//
//  LoginView.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.di) var di: DIContainer
    @State private var viewModel: LoginViewModel?
    @State private var showSignUp = false

    var onLoginSuccess: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // MARK: - Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .padding(.bottom, 48)

                // MARK: - Input Fields
                if let viewModel {
                    VStack(spacing: 16) {
                        TextField("이메일", text: Bindable(viewModel).email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(16)
                            .background(Color("neutral50"))
                            .cornerRadius(12)
                            .font(.medium, 16)

                        SecureField("비밀번호", text: Bindable(viewModel).password)
                            .textContentType(.password)
                            .padding(16)
                            .background(Color("neutral50"))
                            .cornerRadius(12)
                            .font(.medium, 16)
                    }
                    .padding(.horizontal, 24)

                    // MARK: - Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.regular, 14)
                            .padding(.top, 12)
                            .padding(.horizontal, 24)
                    }

                    // MARK: - Login Button
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
                        .background(viewModel.isFormValid ? Color("deepNavy") : Color("neutral300"))
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // MARK: - Sign Up Link
                    Button {
                        showSignUp = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("계정이 없으신가요?")
                                .foregroundStyle(Color("neutral500"))
                            Text("회원가입")
                                .foregroundStyle(Color("deepNavy"))
                        }
                        .font(.medium, 14)
                    }
                    .padding(.top, 16)
                }

                Spacer()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .onChange(of: viewModel?.isLoggedIn) { _, newValue in
                if newValue == true {
                    onLoginSuccess()
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let provider = di.resolve(AuthUseCaseProvider.self)
                viewModel = LoginViewModel(loginUseCase: provider.makeLoginUseCase())
            }
        }
    }
}
