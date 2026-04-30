//
//  ContentView.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.di) var di: DIContainer
    @State private var isLoggedIn: Bool?

    var body: some View {
        Group {
            switch isLoggedIn {
            case .none:
                ProgressView()
            case .some(true):
                RoomLogTab()
            case .some(false):
                LoginView {
                    isLoggedIn = true
                }
            }
        }
        .task {
            let networkClient = di.resolve(NetworkClient.self)
            isLoggedIn = await networkClient.isLoggedIn()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.di, DIContainer.configured())
}
