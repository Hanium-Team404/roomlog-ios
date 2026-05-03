//
//  RoomLogTab.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import SwiftUI


struct RoomLogTab: View {

    // MARK: - Property
    @State var isShowMyPage: Bool = false
    @Environment(\.di) var di
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body
    var body: some View {
        let pathStore = di.resolve(PathStore.self)

        TabView {
            Tab("Home", systemImage: "house") {
                Text("Home")
            }
            Tab("Viewer", systemImage: "magnifyingglass") {
                NavigationStack(path: Bindable(pathStore).defectPath) {
                    ViewerView()
                        .navigationDestination(for: NavigationDestination.self) {
                            NavigationRoutingView(destination: $0)
                        }
                }
            }
            Tab("Profile", systemImage: "person.fill") {
                Text("MyPage")
            }
        }
        .tint(colorScheme == .dark ? .cloudDancer : .mutedBlue)
    }
}

#Preview {
    RoomLogTab()
}

