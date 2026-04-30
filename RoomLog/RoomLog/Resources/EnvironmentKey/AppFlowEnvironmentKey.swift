//
//  AppFlowEnvironmentKey.swift
//  RoomLog
//
//  Created by 김도연 on 5/1/26.
//

import SwiftUI

struct AppFlow {
    let showLogin: () -> Void
    let showMain: () -> Void
    let logout: () -> Void
    
    static let none = AppFlow(
        showLogin: {},
        showMain: {},
        logout: {}
    )
}

struct AppFlowEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppFlow = .none
}

extension EnvironmentValues {
    var appFlow: AppFlow {
        get { self[AppFlowEnvironmentKey.self] }
        set { self[AppFlowEnvironmentKey.self] = newValue }
    }
}
