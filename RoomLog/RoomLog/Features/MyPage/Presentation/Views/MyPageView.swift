//
//  MyPageView.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import SwiftUI

struct MyPageView: View {

    @Environment(\.appFlow) private var appFlow
    @State private var viewModel: MyPageViewModel

    init(provider: MyPageUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: MyPageViewModel(provider: provider)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                profileCard
                menuSection
                infoSection
                accountSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .toolbar {
            ToolbarItem(placement: .title) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128)
                    .padding(.top)
            }
        }
        .task { await viewModel.fetchUser() }
        .alert("닉네임 변경", isPresented: $viewModel.showEditNicknameAlert) {
            TextField("새로운 닉네임", text: $viewModel.editingNickname)
            Button("취소", role: .cancel) {
                viewModel.editingNickname = ""
            }
            Button("변경") {
                Task { await viewModel.updateNickname() }
            }
            .keyboardShortcut(.defaultAction)
        }
        .alert("로그아웃", isPresented: $viewModel.showLogoutConfirm) {
            Button("취소", role: .cancel) {}
            Button("로그아웃", role: .destructive) {
                appFlow.logout()
            }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
        .alert("회원 탈퇴", isPresented: $viewModel.showDeleteAccountConfirm) {
            Button("취소", role: .cancel) {}
            Button("탈퇴", role: .destructive) {
                Task {
                    if await viewModel.deleteAccount() {
                        appFlow.logout()
                    }
                }
            }
        } message: {
            Text("탈퇴하면 모든 데이터가 삭제되며\n복구할 수 없습니다.")
        }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인") {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Profile Card

private extension MyPageView {
    var profileCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blueGray300)

            if let user = viewModel.user {
                VStack(spacing: 6) {
                    Text(user.nickname)
                        .font(.bold, 24)
                        .foregroundStyle(.deepNavy)
                    Text(user.email)
                        .font(.regular, 14)
                        .foregroundStyle(.blueGray500)
                }
            } else if viewModel.isLoading {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

// MARK: - Menu Section

private extension MyPageView {
    var menuSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("설정")
                .font(.semibold, 20)
                .foregroundStyle(.neutral800)

            VStack(spacing: 0) {
                menuRow(icon: "pencil", title: "닉네임 변경") {
                    viewModel.editingNickname = viewModel.user?.nickname ?? ""
                    viewModel.showEditNicknameAlert = true
                }

                Divider().padding(.horizontal, 16)

                menuRow(icon: "camera", title: "카메라 권한 설정") {
                    openAppSettings()
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
    }

    func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.mutedBlue)
                    .frame(width: 24)
                Text(title)
                    .font(.medium, 16)
                    .foregroundStyle(.neutral800)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.blueGray300)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Info Section

private extension MyPageView {
    var infoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("정보")
                .font(.semibold, 20)
                .foregroundStyle(.neutral800)

            VStack(spacing: 0) {
                infoRow(icon: "info.circle", title: "앱 버전", value: appVersion)

                if let user = viewModel.user {
                    Divider().padding(.horizontal, 16)
                    infoRow(
                        icon: "calendar",
                        title: "가입일",
                        value: user.createdAt.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
    }

    func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.mutedBlue)
                .frame(width: 24)
            Text(title)
                .font(.medium, 16)
                .foregroundStyle(.neutral800)
            Spacer()
            Text(value)
                .font(.regular, 14)
                .foregroundStyle(.blueGray500)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Account Section

private extension MyPageView {
    var accountSection: some View {
        VStack(spacing: 0) {
            menuRow(icon: "rectangle.portrait.and.arrow.right", title: "로그아웃") {
                viewModel.showLogoutConfirm = true
            }

            Divider().padding(.horizontal, 16)

            Button {
                viewModel.showDeleteAccountConfirm = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 16))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 24)
                    Text("회원 탈퇴")
                        .font(.medium, 16)
                        .foregroundStyle(.red.opacity(0.7))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.blueGray300)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

// MARK: - Helpers

private extension MyPageView {
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }
}
