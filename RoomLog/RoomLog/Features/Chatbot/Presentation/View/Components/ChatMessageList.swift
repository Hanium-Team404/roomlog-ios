//
//  ChatMessageList.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

/// 대화 말풍선 스크롤 영역. 좁은 입력만 받아 하단 바 등 다른 영역의 변경에 재평가되지 않는다.
struct ChatMessageList: View {
    let messages: [ChatMessage]
    /// 첫 진입(유저 메시지 없음) 시 하자 선택 카드 노출 여부
    let showsDefectSelectCard: Bool
    let isTyping: Bool
    let sendFailed: Bool
    let onSelectDefect: () -> Void
    let onRetrySend: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(messages) { message in
                    ChatMessageBubble(message: message)
                }

                if showsDefectSelectCard {
                    DefectSelectCard(onTap: onSelectDefect)
                }

                if isTyping {
                    ChatTypingIndicator()
                }

                if sendFailed {
                    SendFailedRow(onRetry: onRetrySend)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeInOut(duration: 0.2), value: messages)
        .animation(.easeInOut(duration: 0.2), value: isTyping)
    }
}

// MARK: - 전송 실패 재시도

private struct SendFailedRow: View {
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("답변을 받지 못했어요")
                .font(.medium, 13)
                .foregroundStyle(.secondary)
            Button(action: onRetry) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("다시 시도")
                        .font(.semibold, 13)
                }
                .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ChatMessageList(
        messages: [
            ChatMessage(role: .assistant, content: "안녕하세요! 하자 해결을 도와드리는 RoomLog 챗봇 루미입니다 ☺️")
        ],
        showsDefectSelectCard: true,
        isTyping: false,
        sendFailed: false,
        onSelectDefect: {},
        onRetrySend: {}
    )
}
