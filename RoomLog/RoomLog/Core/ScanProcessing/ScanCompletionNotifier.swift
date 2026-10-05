//
//  ScanCompletionNotifier.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/5/26.
//

import UserNotifications

/// 스캔 처리 완료를 로컬 알림으로 알린다.
/// 앱 안에서는 해당 집의 방 목록에서만 완료가 보이므로, 앱 사용 중이거나 내려가 있어도 알림으로 알린다.
@MainActor
protocol ScanCompletionNotifying {
    /// 시스템 권한 창은 첫 호출에서만 뜬다
    func requestAuthorization()
    /// - Parameter houseId: 알림을 누르면 이 집의 스캔 상태 시트로 이동한다
    func notify(title: String, body: String, houseId: Int)
}

final class ScanCompletionNotifier: ScanCompletionNotifying {

    /// 같은 식별자로 보내 이전 스캔의 완료 알림을 대체한다
    private let identifier = "scan-completed"
    private nonisolated static let houseIdKey = "houseId"

    func requestAuthorization() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                log("알림 권한 granted=\(granted)")
            } catch {
                log("알림 권한 요청 실패: \(error)")
            }
        }
    }

    func notify(title: String, body: String, houseId: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [Self.houseIdKey: houseId]
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                log("완료 알림 등록 실패: \(error)")
            }
        }
    }

    private func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[ScanNotification] \(message())")
        #endif
    }

    /// 탭한 알림이 스캔 완료 알림이면 집 ID를 돌려준다
    nonisolated static func houseId(from userInfo: [AnyHashable: Any]) -> Int? {
        userInfo[houseIdKey] as? Int
    }
}
