//
//  MockScanBackgroundContinuation.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/5/26.
//

import Foundation
@testable import RoomLog

@MainActor
final class MockScanBackgroundContinuation: ScanBackgroundContinuing {

    struct Display: Equatable {
        let title: String
        let subtitle: String
    }

    // MARK: - Call Tracking

    private(set) var trackedProgresses: [Progress] = []
    /// 진행 중인 연장에 반영된 문구만 기록한다 (begin 포함)
    private(set) var displays: [Display] = []
    /// 진행 중인 연장을 끝낸 결과만 기록한다 — 실제 구현처럼 연장이 없을 때의 end는 무시한다
    private(set) var endResults: [Bool] = []
    /// 연장 유무와 관계없이 모든 end 호출을 기록한다 — 끝난 뒤 늦게 온 잘못된 호출을 잡기 위함
    private(set) var allEndCalls: [Bool] = []
    private var isActive = false

    // MARK: - ScanBackgroundContinuing

    func begin(tracking progress: Progress, title: String, subtitle: String) {
        trackedProgresses.append(progress)
        displays.append(Display(title: title, subtitle: subtitle))
        isActive = true
    }

    func update(title: String, subtitle: String) {
        guard isActive else { return }
        displays.append(Display(title: title, subtitle: subtitle))
    }

    func end(success: Bool) {
        allEndCalls.append(success)
        guard isActive else { return }
        isActive = false
        endResults.append(success)
    }
}
