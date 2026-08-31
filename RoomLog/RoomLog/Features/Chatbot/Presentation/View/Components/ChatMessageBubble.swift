//
//  ChatMessageBubble.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        // 최상위 switch를 단일 루트 컨테이너로 감싸 lazy 컨테이너의 row identity를 상수로 유지한다
        VStack {
            switch message.role {
            case .user:
                userBubble
            case .assistant:
                assistantBubble
            }
        }
    }

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 48)
            VStack(alignment: .trailing, spacing: 6) {
                if let defect = message.attachedDefect {
                    DefectAttachmentChip(defect: defect)
                }
                Text(message.content)
                    .font(.medium, 15)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: .rect(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(decorative: "Roomi")
                .resizable()
                .scaledToFit()
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text("루미")
                    .font(.medium, 12)
                    .foregroundStyle(.secondary)
                Text(message.content)
                    .font(.medium, 15)
                    .foregroundStyle(Color.neutral800)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6), in: .rect(cornerRadius: 16))
            }
            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatMessageBubble(
            message: ChatMessage(role: .assistant, content: "안녕하세요! 하자 해결을 도와드리는 RoomLog 챗봇 루미입니다 ☺️")
        )
        ChatMessageBubble(
            message: ChatMessage(role: .user, content: "벽지 찢어짐은 어떻게 보수하나요?")
        )
        ChatMessageBubble(
            message: ChatMessage(
                role: .user,
                content: "이 하자는 어떻게 고치나요?",
                attachedDefect: ChatSelectableDefect(
                    id: 1, type: .scratch, severity: .low,
                    location: "복도 바닥 타일", roomName: "거실", imageURL: nil
                )
            )
        )
    }
    .padding(16)
}
