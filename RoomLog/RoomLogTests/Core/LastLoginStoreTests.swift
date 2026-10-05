//
//  LastLoginStoreTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/5/26.
//

import Testing
import Foundation
@testable import RoomLog

final class LastLoginStoreTests {

    /// 테스트마다 고유한 suite를 사용해 병렬 실행 간 간섭을 차단
    private let suiteName: String
    private let defaults: UserDefaults
    private let sut: LastLoginStore

    init() throws {
        suiteName = "LastLoginStoreTests-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        sut = LastLoginStore(userDefaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func 기록이_없으면_다른_계정으로_본다() {
        #expect(sut.recordLogin(userId: 1))
    }

    @Test func 같은_계정으로_다시_로그인하면_다른_계정이_아니다() {
        _ = sut.recordLogin(userId: 1)

        #expect(sut.recordLogin(userId: 1) == false)
    }

    @Test func 다른_계정으로_로그인하면_다른_계정으로_본다() {
        _ = sut.recordLogin(userId: 1)

        #expect(sut.recordLogin(userId: 2))
    }

    @Test func 마지막_로그인_계정을_기준으로_비교한다() {
        _ = sut.recordLogin(userId: 1)
        _ = sut.recordLogin(userId: 2)

        #expect(sut.recordLogin(userId: 2) == false)
        #expect(sut.recordLogin(userId: 1))
    }
}
