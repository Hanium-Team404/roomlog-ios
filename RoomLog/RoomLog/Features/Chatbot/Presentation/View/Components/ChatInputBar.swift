//
//  ChatInputBar.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

struct ChatInputBar: View {
    let isSending: Bool
    /// 세션이 준비되지 않았거나 로딩/실패 상태면 false — 입력 유실 방지를 위해 전송 차단
    let canSend: Bool
    let attachedDefect: ChatSelectableDefect?
    let onRemoveAttachment: () -> Void
    let onAttach: () -> Void
    let onSend: (String) -> Void

    /// 키 입력마다 부모(채팅 화면 전체)가 재평가되지 않도록 텍스트는 입력 바가 소유한다
    @State private var text = ""

    private var isSendDisabled: Bool {
        isSending || !canSend || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let attachedDefect {
                DefectAttachmentChip(defect: attachedDefect, onRemove: onRemoveAttachment)
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
            inputRow
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .glassEffect(.regular, in: .rect(cornerRadius: 25))
    }

    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Button(action: onAttach) {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color.neutral600)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .accessibilityLabel("하자 첨부")

            TextField("메시지를 입력하세요...", text: $text, axis: .vertical)
                .font(.medium, 15)
                .lineLimit(1...4)
                .padding(.vertical, 8)
                .onChange(of: text) { _, newValue in
                    // 서버 제한 300자 초과 입력 차단
                    if newValue.count > ChatbotViewModel.maxMessageLength {
                        text = String(newValue.prefix(ChatbotViewModel.maxMessageLength))
                    }
                }

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSendDisabled ? Color(.systemGray) : .white)
                    .frame(width: 30, height: 30)
                    .background(
                        isSendDisabled ? Color(.systemGray5) : Color.accentColor,
                        in: .circle
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .disabled(isSendDisabled)
            .accessibilityLabel("전송")
        }
    }

    private func send() {
        let message = text
        text = ""
        onSend(message)
    }
}

#Preview {
    VStack(spacing: 20) {
        ChatInputBar(
            isSending: false,
            canSend: true,
            attachedDefect: nil,
            onRemoveAttachment: {},
            onAttach: {},
            onSend: { _ in }
        )
        ChatInputBar(
            isSending: false,
            canSend: true,
            attachedDefect: ChatSelectableDefect(
                id: 1, type: .scratch, severity: .low,
                location: "복도 바닥 타일", roomName: "거실", imageURL: nil
            ),
            onRemoveAttachment: {},
            onAttach: {},
            onSend: { _ in }
        )
    }
    .padding(16)
}
