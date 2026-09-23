//
//  ScenePhaseGate.swift
//  RoomLog
//
//  Created by 김도연 on 9/22/26.
//

import SwiftUI

/// scenePhase에 따라 닫히고 열리는 문. 폴링 루프는 문이 열릴 때까지 대기한다.
///
/// 백그라운드에서 API 호출을 멈추고, 포그라운드 복귀 시 대기 중인 루프를
/// 즉시 깨워 재개 지연 없이 폴링을 이어가게 한다.
@MainActor
final class ScenePhaseGate {

    // MARK: - State

    private var isClosed = false
    /// 문이 닫힌 동안 파킹된 대기자. 단일 processingTask 관례상 항상 1개 이하.
    private var waiter: CheckedContinuation<Void, Never>?

    /// 생명주기 전환 횟수. 요청 전후로 값이 다르면 전환에 물려 끊긴 실패다
    /// 에러가 도착한 시점엔 이미 포그라운드일 수 있어 불리언으로는 판별할 수 없다.
    private(set) var transitionCount = 0

    // MARK: - Gate Control

    /// scenePhase를 게이트 상태에 반영한다.
    /// `.inactive`(전화 배너, 제어센터 등)에서도 닫는 것은 의도된 정책
    /// `.active` 복귀 시 대기자를 즉시 깨우므로 짧은 중단에도 재개 지연이 없다.
    func update(_ phase: ScenePhase) {
        transitionCount += 1
        isClosed = (phase != .active)
        if !isClosed {
            wake()
        }
    }

    /// 문이 열릴 때까지 대기. 이미 열려 있으면 즉시 통과한다.
    /// 취소로 깨어난 경우엔 재파킹하지 않고 빠져나가므로 호출부가 취소를 처리해야 한다.
    func waitUntilOpen() async {
        while isClosed && !Task.isCancelled {
            await withCheckedContinuation { continuation in
                // 파킹 직전에 복귀 이벤트가 먼저 도착했다면 대기하지 않고 통과 (lost wakeup 방어)
                guard isClosed else {
                    continuation.resume()
                    return
                }
                // 파킹 슬롯이 이미 차 있다면 새 Task 생성 지점이 wake()를 빼먹은 것
                assert(waiter == nil, "파킹 슬롯은 항상 1개여야 한다")
                waiter?.resume()
                waiter = continuation
            }
        }
    }

    /// 대기자를 강제로 깨운다. Task 취소를 파킹된 루프에 인지시킬 때 사용한다.
    func wake() {
        waiter?.resume()
        waiter = nil
    }

    #if DEBUG
    /// 테스트에서 루프가 실제로 파킹됐는지 관측하기 위한 노출
    var isParked: Bool { waiter != nil }
    #endif
}
