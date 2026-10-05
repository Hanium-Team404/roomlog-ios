//
//  MockScanCompletionNotifier.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/5/26.
//

import Foundation
@testable import RoomLog

@MainActor
final class MockScanCompletionNotifier: ScanCompletionNotifying {

    struct SentNotification: Equatable {
        let title: String
        let body: String
        let houseId: Int
    }

    // MARK: - Call Tracking

    private(set) var notifications: [SentNotification] = []

    // MARK: - ScanCompletionNotifying

    func requestAuthorization() {}

    func notify(title: String, body: String, houseId: Int) {
        notifications.append(SentNotification(title: title, body: body, houseId: houseId))
    }
}
