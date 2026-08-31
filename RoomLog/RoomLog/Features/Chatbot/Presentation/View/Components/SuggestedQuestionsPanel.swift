//
//  SuggestedQuestionsPanel.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

/// 입력창 위에 붙는 추천 질문 접이식 패널 (카카오톡 채널 챗봇 스타일).
/// 질문 선택 또는 메시지 전송 시 접히고, 컴팩트 필을 탭하면 다시 펼쳐진다.
/// 펼친 상태에서 아래로 스와이프해도 접힌다.
struct SuggestedQuestionsPanel: View {
    let questions: [ChatSuggestedQuestion]
    @Binding var isExpanded: Bool
    let onSelect: (ChatSuggestedQuestion) -> Void

    var body: some View {
        if isExpanded {
            expandedPanel
        } else {
            collapsedPill
        }
    }

    // MARK: - 펼침 상태

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            ForEach(questions.enumerated(), id: \.element) { index, question in
                if index > 0 {
                    Divider()
                        .padding(.horizontal, 20)
                }
                Button {
                    onSelect(question)
                } label: {
                    Text(question.question)
                        .font(.medium, 15)
                        .foregroundStyle(Color.neutral800)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    if value.translation.height > 15 {
                        withAnimation(.snappy) {
                            isExpanded = false
                        }
                    }
                }
        )
    }

    // MARK: - 접힘 상태

    private var collapsedPill: some View {
        Button {
            withAnimation(.snappy) {
                isExpanded = true
            }
        } label: {
            HStack(spacing: 6) {
                Text("추천 질문")
                    .font(.semibold, 13)
                    .foregroundStyle(Color.neutral800)
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

#Preview {
    @Previewable @State var isExpanded = true
    SuggestedQuestionsPanel(
        questions: [
            ChatSuggestedQuestion(question: "3D 스캔은 어떻게 하나요?", guide: "GUIDE_SCAN"),
            ChatSuggestedQuestion(question: "하자 분석은 어떻게 요청하나요?", guide: "GUIDE_ANALYSIS"),
            ChatSuggestedQuestion(question: "내 방 비교 기능이 뭔가요?", guide: "GUIDE_COMPARE"),
            ChatSuggestedQuestion(question: "수리 업체 추천을 받고 싶어요", guide: "GUIDE_ESTIMATE")
        ],
        isExpanded: $isExpanded
    ) { _ in }
        .padding(16)
}
