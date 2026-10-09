//
//  CheckSessionUseCase.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/9/26.
//

import Foundation

/// 사용자 조회 함수를 주입받아 ID만 노출한다.
/// 실제 조회(MyPage의 GetUserUseCase)는 조립부(RoomLogApp)에서 연결하므로 Splash는 MyPage를 참조하지 않는다
struct CheckSessionUseCase: CheckSessionUseCaseProtocol {

    private let fetchUserId: () async throws -> Int

    init(fetchUserId: @escaping () async throws -> Int) {
        self.fetchUserId = fetchUserId
    }

    func execute() async throws -> Int {
        try await fetchUserId()
    }
}
