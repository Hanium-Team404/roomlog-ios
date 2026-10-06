//
//  AppRouterTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/6/26.
//

import Testing
import Foundation
@testable import RoomLog

/// 로그아웃 시 스캔 취소 요청 대기 상한 테스트.
/// 상한이 지켜지지 않으면 서버가 늦을 때 토큰 삭제가 무한정 밀린다 (#204).
struct AppRouterTests {

    /// 끝나지 않는 Task를 기다려도 상한 안에 돌아와야 한다
    @Test
    func 대기_상한이_지나면_Task가_끝나지_않아도_반환한다() async {
        let neverFinishing = Task<Void, Never> {
            await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in }
        }
        let clock = ContinuousClock()

        let elapsed = await clock.measure {
            await AppRouter.wait(for: neverFinishing, upTo: .milliseconds(200))
        }

        #expect(elapsed >= .milliseconds(200))
        #expect(elapsed < .seconds(2), "상한 \(Duration.milliseconds(200)) 을 넘겨 \(elapsed) 걸림")
        neverFinishing.cancel()
    }

    /// Task가 먼저 끝나면 상한까지 기다리지 않는다
    @Test
    func Task가_먼저_끝나면_즉시_반환한다() async {
        let quick = Task<Void, Never> {}
        let clock = ContinuousClock()

        let elapsed = await clock.measure {
            await AppRouter.wait(for: quick, upTo: .seconds(10))
        }

        #expect(elapsed < .seconds(2))
    }
}
