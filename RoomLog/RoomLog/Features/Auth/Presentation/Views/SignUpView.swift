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

            // MARK: - Title
            Text("회원가입")
                .font(.bold, 24)
                .foregroundStyle(Color("neutral900"))
                .padding(.bottom, 32)

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
                        .textContentType(.newPassword)
                        .padding(16)
                        .background(Color("neutral50"))
                        .cornerRadius(12)
                        .font(.medium, 16)

                    TextField("닉네임", text: Bindable(viewModel).nickname)
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

                // MARK: - Sign Up Button
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
                    .background(viewModel.isFormValid ? Color("deepNavy") : Color("neutral300"))
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color("neutral900"))
                }
            }
        }
        .onChange(of: viewModel?.isSignUpCompleted) { _, newValue in
            if newValue == true {
                dismiss()
            }
        }
        .onAppear {
            if viewModel == nil {
                let provider = di.resolve(AuthUseCaseProvider.self)
                viewModel = SignUpViewModel(signUpUseCase: provider.makeSignUpUseCase())
            }
        }
    }
}
