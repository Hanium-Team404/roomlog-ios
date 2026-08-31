//
//  ChatTypingIndicator.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

/// GPT 답변 대기 중 표시하는 타이핑 인디케이터 말풍선
struct ChatTypingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(decorative: "Roomi")
                .resizable()
                .scaledToFit()
                .frame(width: 36)

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.neutral600)
                        .frame(width: 7, height: 7)
                        .opacity(isAnimating ? 0.25 : 1)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6), in: .rect(cornerRadius: 16))

            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { isAnimating = true }
    }
}

#Preview {
    ChatTypingIndicator()
        .padding(16)
}
