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
    /// 자동 로그인에 성공한 계정. 마지막 로그인 계정 기록에 쓴다
    private(set) var userId: Int?

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
            let user = try await getUserUseCase.execute()
            userId = user.id
            loggedIn = true
        } catch {
            loggedIn = false
        }

        _ = try? await delay

        isLoggedin = loggedIn
        isChecked = true
    }
}
