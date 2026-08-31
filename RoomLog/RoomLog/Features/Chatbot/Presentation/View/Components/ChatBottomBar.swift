//
//  ChatBottomBar.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

/// 하단 영역 (추천 질문 패널 + 입력 바). 대화 영역과 invalidation 경계를 분리한다.
struct ChatBottomBar: View {
    let suggestedQuestions: [ChatSuggestedQuestion]
    @Binding var isPanelExpanded: Bool
    let attachedDefect: ChatSelectableDefect?
    let isSending: Bool
    let canSend: Bool
    let onSelectQuestion: (ChatSuggestedQuestion) -> Void
    let onRemoveAttachment: () -> Void
    let onAttach: () -> Void
    let onSend: (String) -> Void

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(spacing: 10) {
                if !suggestedQuestions.isEmpty {
                    SuggestedQuestionsPanel(
                        questions: suggestedQuestions,
                        isExpanded: $isPanelExpanded,
                        onSelect: onSelectQuestion
                    )
                }

                ChatInputBar(
                    isSending: isSending,
                    canSend: canSend,
                    attachedDefect: attachedDefect,
                    onRemoveAttachment: onRemoveAttachment,
                    onAttach: onAttach,
                    onSend: onSend
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .animation(.snappy, value: isPanelExpanded)
        .animation(.snappy, value: attachedDefect)
    }
}
