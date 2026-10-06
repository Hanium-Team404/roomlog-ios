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
@MainActor
@Suite(.timeLimit(.minutes(3)))
struct AppRouterTests {

    /// 타이머가 끝나면 원래 작업을 끝내거나 취소하지 않고 반환한다
    @Test
    func 대기_상한이_지나면_Task가_끝나지_않아도_반환한다() async {
        let (completion, release) = AsyncStream<Void>.makeStream()
        var taskFinished = false
        let pending = Task {
            for await _ in completion {}
            taskFinished = true
        }
        defer { release.finish() }

        await withTaskCancellationHandler {
            await confirmation("설정한 대기 상한으로 타이머를 시작한다") { timerStarted in
                await AppRouter.wait(for: pending, upTo: .milliseconds(200)) { duration in
                    #expect(duration == .milliseconds(200))
                    timerStarted()
                    // 실제 시간을 기다리지 않고 타이머 만료를 전달한다
                }
            }
        } onCancel: {
            // 회귀로 대기가 끝나지 않아도 전체 테스트 제한에 걸리면 작업을 정리한다
            release.finish()
        }

        #expect(taskFinished == false)
        #expect(pending.isCancelled == false)
        release.finish()
        await pending.value
    }

    /// Task가 먼저 끝나면 상한까지 기다리지 않는다
    @Test
    func Task가_먼저_끝나면_즉시_반환한다() async {
        let (completion, release) = AsyncStream<Void>.makeStream()
        let (timeout, releaseTimeout) = AsyncStream<Void>.makeStream()
        var taskFinished = false
        let pending = Task {
            for await _ in completion {}
            taskFinished = true
        }
        defer {
            release.finish()
            releaseTimeout.finish()
        }

        await withTaskCancellationHandler {
            await confirmation("타이머가 대기 중일 때 원래 작업이 끝난다") { timerStarted in
                await AppRouter.wait(for: pending, upTo: .seconds(10)) { duration in
                    #expect(duration == .seconds(10))
                    timerStarted()
                    release.finish()
                    for await _ in timeout {}
                    try Task.checkCancellation()
                    Issue.record("타이머 만료 전에 작업 완료만으로 반환해야 합니다")
                }
            }
        } onCancel: {
            release.finish()
            releaseTimeout.finish()
        }

        #expect(taskFinished)
        #expect(pending.isCancelled == false)
        await pending.value
    }
}
