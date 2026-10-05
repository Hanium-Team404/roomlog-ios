//
//  LastLoginStore.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/5/26.
//

import Foundation

/// 마지막으로 로그인한 계정을 기억해 다른 계정으로 로그인했는지 판별한다.
/// 세션 만료로 `logout()` 정리 없이 로그인 화면에 온 경우, 이전 계정의 기기 내 스캔 상태를 정리할지 정하는 데 쓴다.
///
/// `AppRouter` init 기본 인자로 쓰이므로 nonisolated — UserDefaults는 스레드 안전하다.
nonisolated struct LastLoginStore {

    private static let userIdKey = "LastLogin_userId"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// 이번 로그인 계정을 기록하고, 직전 기록과 다른 계정인지 돌려준다.
    /// 기록이 없으면(첫 로그인, 기록 도입 전 사용자) 남은 상태의 주인을 알 수 없으므로 다른 계정으로 본다.
    func recordLogin(userId: Int) -> Bool {
        let previous = userDefaults.object(forKey: Self.userIdKey) as? Int
        userDefaults.set(userId, forKey: Self.userIdKey)
        return previous != userId
    }
}
