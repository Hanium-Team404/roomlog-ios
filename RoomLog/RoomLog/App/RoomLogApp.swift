//
//  RoomLogApp.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import SwiftUI

@main
struct RoomLogApp: App {
    let di = DIContainer.configured()
    
    var body: some Scene {
        WindowGroup {
            RoomLogTab()
                .environment(\.di, di)
        }
    }
}
