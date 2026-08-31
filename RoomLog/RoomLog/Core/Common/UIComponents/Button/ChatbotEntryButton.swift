//
//  ChatbotEntryButton.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

extension View {
    /// 탭 루트 화면 우하단, 탭바 위에 떠 있는 챗봇 진입 버튼 (GitHub 앱 Copilot 버튼 스타일).
    /// 루트 뷰의 overlay로 붙이므로 화면이 push되면 함께 사라진다.
    func chatbotEntryButton(action: @escaping () -> Void) -> some View {
        overlay(alignment: .bottomTrailing) {
            ChatbotEntryButton(action: action)
                .padding(.trailing, 20)
                .padding(.bottom, 6)
        }
    }
}

struct ChatbotEntryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("Roomi")
                .resizable()
                .scaledToFit()
                .frame(width: 30)
                .frame(width: 52, height: 52)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
    }
}

#Preview {
    Color.clear
        .chatbotEntryButton {}
}
