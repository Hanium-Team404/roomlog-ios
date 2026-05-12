//
//  MyPageViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

@Observable
final class MyPageViewModel {

    // MARK: - Provider

    private let provider: MyPageUseCaseProvider

    // MARK: - State

    private(set) var user: User?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    var showEditNicknameAlert: Bool = false
    var editingNickname: String = ""
    var showDeleteAccountConfirm: Bool = false
    var showLogoutConfirm: Bool = false

    // MARK: - Init

    init(provider: MyPageUseCaseProvider) {
        self.provider = provider
    }

    // MARK: - Actions

    @MainActor
    func fetchUser() async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await provider.makeGetUserUseCase().execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func updateNickname() async {
        let trimmed = editingNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try await provider.makeUpdateUserUseCase().execute(nickname: trimmed)
            user = try await provider.makeGetUserUseCase().execute()
            editingNickname = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteAccount() async {
        do {
            try await provider.makeDeleteUserUseCase().execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
