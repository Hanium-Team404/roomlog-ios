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
                } else if message.defectId != nil {
                    Label("첨부한 하자", systemImage: "paperclip")
                        .font(.medium, 13)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6).opacity(0.8), in: .rect(cornerRadius: 14))
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
                if let defectId = message.linkedDefectId {
                    selfRepairGuideLink(defectId: defectId)
                }
            }
            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 값 기반 링크라 챗봇이 홈·뷰어 어느 탭 스택에 있든 그 스택에 쌓이고, 뒤로가기로 챗봇에 돌아온다
    private func selfRepairGuideLink(defectId: Int) -> some View {
        NavigationLink(value: NavigationDestination.defect(.defectDetail(defectId: defectId, scrollsToSelfRepair: true))) {
            HStack(spacing: 6) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 12, weight: .semibold))
                Text("자가 수리 안내 보기")
                    .font(.semibold, 13)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
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
            ChatMessageBubble(
                message: ChatMessage(
                    role: .assistant,
                    content: "이 하자는 벽지 들뜸으로 보여요. 자세한 방법은 자가 수리 안내 페이지에서 확인해 주세요.",
                    defectId: 1
                )
            )
        }
        .padding(16)
    }
}
