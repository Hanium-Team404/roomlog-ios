//
//  SignUpView.swift
//  RoomLog
//
//  Created by 김도연 on 4/30/26.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.di) var di: DIContainer
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: SignUpViewModel?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            titleSection
            if let viewModel {
                inputFields(viewModel)
                errorMessage(viewModel)
                signUpButton(viewModel)
            }
            Spacer()
        }
        .onAppear {
            if viewModel == nil {
                let provider = di.resolve(AuthUseCaseProvider.self)
                viewModel = SignUpViewModel(signUpUseCase: provider.signUpUseCase)
            }
        }
        .onChange(of: viewModel?.isSignUpCompleted) { _, newValue in
            if newValue == true {
                dismiss()
            }
        }
    }
}

// MARK: - Subviews
private extension SignUpView {

    var titleSection: some View {
        Text("회원가입")
            .font(.bold, 24)
            .foregroundStyle(.neutral900)
            .padding(.bottom, 32)
    }

    func inputFields(_ viewModel: SignUpViewModel) -> some View {
        VStack(spacing: 16) {
            TextField("이메일", text: Bindable(viewModel).email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(16)
                .background(.neutral50, in: RoundedRectangle(cornerRadius: 12))
                .font(.medium, 16)

            SecureField("비밀번호", text: Bindable(viewModel).password)
                .textContentType(.newPassword)
                .padding(16)
                .background(.neutral50, in: RoundedRectangle(cornerRadius: 12))
                .font(.medium, 16)

            TextField("닉네임", text: Bindable(viewModel).nickname)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(16)
                .background(.neutral50, in: RoundedRectangle(cornerRadius: 12))
                .font(.medium, 16)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    func errorMessage(_ viewModel: SignUpViewModel) -> some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .font(.regular, 14)
                .padding(.top, 12)
                .padding(.horizontal, 24)
        }
    }

    func signUpButton(_ viewModel: SignUpViewModel) -> some View {
        Button {
            Task { await viewModel.signUp() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("회원가입")
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
}
