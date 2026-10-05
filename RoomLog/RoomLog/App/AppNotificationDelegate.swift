//
//  AppNotificationDelegate.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/5/26.
//

import UserNotifications

/// 앱 알림 처리.
/// - 앱이 화면에 떠 있을 때도 배너를 띄운다. 이 delegate가 없으면 시스템이 포그라운드 알림을 숨긴다
/// - 스캔 완료 알림을 누르면 해당 집의 스캔 상태 시트로 이동을 요청한다
///
/// 알림 센터는 delegate를 약하게 잡으므로 소유자(RoomLogApp)가 수명을 유지해야 한다.
nonisolated final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    private let onOpenScanStatus: @MainActor @Sendable (Int) -> Void

    init(onOpenScanStatus: @escaping @MainActor @Sendable (Int) -> Void) {
        self.onOpenScanStatus = onOpenScanStatus
    }

    // ⚠️ 아래 두 메서드는 `async` 버전으로 바꾸지 않는다.
    //
    // 시스템은 이 메서드를 메인 스레드에서 부르고, 끝나면 completionHandler로 알려주기를 기다린다.
    // async 버전으로 쓰면 Swift가 그 사이를 이어주는 변환 코드를 자동으로 만드는데,
    // 이 클래스는 nonisolated라서 그 변환 코드가 async 본문을 백그라운드 스레드에서 실행하고
    // completionHandler도 백그라운드 스레드에서 호출하게 된다.
    // 그러면 시스템이 이어서 하는 UIKit 작업이 메인 스레드가 아니라서
    // "Call must be made on main thread"로 앱이 종료된다. 특히 앱 밖에서 알림을 눌러 들어올 때 매번 재현됐다.
    //
    // 그래서 completionHandler 버전을 유지해 메인 스레드에서 바로 응답하고,
    // 화면 이동처럼 MainActor가 필요한 일만 Task로 넘긴다.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let houseId = ScanCompletionNotifier.houseId(from: response.notification.request.content.userInfo) {
            let open = onOpenScanStatus
            Task { @MainActor in open(houseId) }
        }
        completionHandler()
    }
}
