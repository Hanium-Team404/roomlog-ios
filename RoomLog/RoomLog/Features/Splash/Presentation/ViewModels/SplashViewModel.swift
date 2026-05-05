//
//  SplashViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 5/2/26.
//

import Foundation
import Observation

@Observable
final class SplashViewModel {

    private let networkClient: NetworkClient
    private let getUserUseCase: GetUserUseCaseProtocol
    private let tokenStore: TokenStore

    private(set) var isChecked: Bool = false
    private(set) var isLoggedin: Bool = false

    init(
        networkClient: NetworkClient,
        getUserUseCase: GetUserUseCaseProtocol,
        tokenStore: TokenStore
    ) {
        self.networkClient = networkClient
        self.getUserUseCase = getUserUseCase
        self.tokenStore = tokenStore
    }

    @MainActor
    func checkAuth() async {
        async let delay = Task.sleep(for: .seconds(2))

        let loggedIn: Bool
        do {
            _ = try await getUserUseCase.execute()
            loggedIn = true
        } catch {
            loggedIn = false
        }

        _ = try? await delay

        isLoggedin = loggedIn
        isChecked = true
    }
}
