//
//  MyPageView.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import SwiftUI

struct MyPageView: View {
    @Environment(\.appFlow) private var appFlow

    var body: some View {
        List {
            Section {
                Button(role: .destructive) {
                    appFlow.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("로그아웃")
                    }
                }
            }
        }
        .navigationTitle("마이페이지")
    }
}
