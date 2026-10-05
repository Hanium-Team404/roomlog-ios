//
//  ScanBackgroundContinuation.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/5/26.
//

import BackgroundTasks
import Foundation

/// 스캔 처리(압축·업로드·생성 대기) 중 앱이 백그라운드로 가도 suspend되지 않도록 실행 시간 연장을 요청한다.
/// 처리 자체는 파이프라인이 수행하고, 여기서는 연장 요청·진행 표시·종료만 맡는다.
@MainActor
protocol ScanBackgroundContinuing {
    /// 연장을 요청하고, 이후 `progress`의 진행을 시스템 진행 표시(Live Activity)에 반영한다
    func begin(tracking progress: Progress, title: String, subtitle: String)
    func update(title: String, subtitle: String)
    /// 연장 종료. 진행 중인 연장이 없으면 아무것도 하지 않는다
    func end(success: Bool)
}

final class ScanBackgroundContinuation: ScanBackgroundContinuing {

    static let shared = ScanBackgroundContinuation()

    /// Info.plist `BGTaskSchedulerPermittedIdentifiers`의 와일드카드(`<번들 ID>.scan-upload.*`) 아래 이름이어야 한다.
    /// 연장 태스크는 정확히 일치하는 식별자로는 제출할 수 없다
    private let identifier = "\(Bundle.main.bundleIdentifier ?? "").scan-upload.processing"
    /// 같은 식별자를 두 번 등록하면 시스템이 앱을 종료하므로 프로세스당 한 번만 등록한다
    private var isRegistered = false
    private var trackedProgress: Progress?
    /// 승인 전에 끝난 처리의 결과. 늦게 승인된 태스크를 같은 결과로 닫는다
    private var finishedBeforeAttach = false
    private var title = ""
    private var subtitle = ""
    private var task: BGContinuedProcessingTask?
    private var observation: NSKeyValueObservation?

    private init() {}

    func begin(tracking progress: Progress, title: String, subtitle: String) {
        trackedProgress = progress
        self.title = title
        self.subtitle = subtitle
        registerIfNeeded()

        let request = BGContinuedProcessingTaskRequest(identifier: identifier, title: title, subtitle: subtitle)
        // 대기열에 들어가면 이미 시작된 처리와 연장 시점이 어긋난다 — 바로 받지 못하면 연장 없이 진행한다
        request.strategy = .fail
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            log("연장 요청 실패: \(error)")
        }
    }

    func update(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
        task?.updateTitle(title, subtitle: subtitle)
    }

    func end(success: Bool) {
        observation?.invalidate()
        observation = nil
        if let task {
            if success {
                task.progress.completedUnitCount = task.progress.totalUnitCount
            }
            task.setTaskCompleted(success: success)
            self.task = nil
            log("연장 종료 success=\(success)")
        } else if trackedProgress != nil {
            // 진행 중인 처리가 있을 때만 기록한다 — 새 처리 직전의 정리 호출이 결과를 덮어쓰지 않도록
            finishedBeforeAttach = success
        }
        trackedProgress = nil
    }

    // MARK: - Private

    private func registerIfNeeded() {
        guard !isRegistered else { return }
        // 핸들러는 MainActor 격리를 물려받으므로 큐는 반드시 .main이어야 한다 (nil이면 런타임 격리 검사에서 크래시)
        isRegistered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { [weak self] task in
            guard let task = task as? BGContinuedProcessingTask else { return }
            self?.attach(task)
        }
    }

    /// 시스템이 연장을 승인하면 호출된다. 처리는 이미 진행 중이므로 진행 표시 연결과 만료 처리만 한다
    private func attach(_ task: BGContinuedProcessingTask) {
        guard let trackedProgress else {
            log("승인 전에 처리가 끝나 바로 종료 success=\(finishedBeforeAttach)")
            if finishedBeforeAttach {
                task.progress.totalUnitCount = 100
                task.progress.completedUnitCount = 100
            }
            task.setTaskCompleted(success: finishedBeforeAttach)
            return
        }
        log("연장 승인")
        self.task = task
        task.updateTitle(title, subtitle: subtitle)

        // 하위 진행률로 붙이지 않고 값만 옮긴다 — 태스크 진행률이 취소되면 하위로 전파돼 압축이 중단된다
        let taskProgress = task.progress
        taskProgress.totalUnitCount = 100
        observation = trackedProgress.observe(\.fractionCompleted, options: [.initial]) { @Sendable (progress, _) in
            taskProgress.completedUnitCount = Int64(progress.fractionCompleted * 100)
        }

        task.expirationHandler = { @Sendable [weak self] in
            Task { @MainActor [weak self] in
                self?.expire()
            }
        }
    }

    /// 유저 중지와 시스템 만료를 구분할 수 없으므로 스캔은 취소하지 않고 연장만 끝낸다.
    /// 이후 앱은 평소처럼 suspend돼 처리가 멈추고, 복귀하면 폴링은 이어지며 끊긴 업로드는 재시도할 수 있다.
    /// 스캔 자체는 실패가 아니므로 시스템의 실패 표시와 함께 보일 문구를 일시 중지로 바꾼 뒤 끝낸다
    private func expire() {
        log("연장 만료 (시스템 종료 또는 유저 중지)")
        update(title: "스캔 일시 중지", subtitle: "앱에서 이어서 진행할 수 있습니다")
        end(success: false)
    }

    private func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[ScanBackground] \(message())")
        #endif
    }
}
