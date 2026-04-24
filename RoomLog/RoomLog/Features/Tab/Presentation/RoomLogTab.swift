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
    
    // MARK: - Body
    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        
        TabView {
            Tab("", systemImage: "house") {
                Text("Home")
            }
            Tab("", systemImage: "wrench.and.screwdriver.fill") {
                NavigationStack(path: Bindable(pathStore).defectPath) {
                    ViewerView()
                        .navigationDestination(for: NavigationDestination.self) {
                            NavigationRoutingView(destination: $0)
                        }
                }
            }
            Tab("", systemImage: "person.fill", role: .search) {
                Text("MyPage")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RoomLogTab()
}

