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
        TabView {
            Tab("", systemImage: "house") {
                Text("Home")
            }
            Tab("", systemImage: "wrench.and.screwdriver.fill") {
                Text("Defect")
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

