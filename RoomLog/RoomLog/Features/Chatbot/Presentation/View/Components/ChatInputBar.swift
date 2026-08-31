//
//  ChatInputBar.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let attachedDefect: ChatSelectableDefect?
    let onRemoveAttachment: () -> Void
    let onAttach: () -> Void
    let onSend: () -> Void

    private var isSendDisabled: Bool {
        isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        .padding(.vertical, 5)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 25))
    }

    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button(action: onAttach) {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color.neutral600)
                    .frame(width: 34, height: 34)
            }

            TextField("메세지를 입력하세요...", text: $text, axis: .vertical)
                .font(.medium, 15)
                .lineLimit(1...4)
                .padding(.vertical, 8)
                .onChange(of: text) { _, newValue in
                    // 서버 제한 300자 초과 입력 차단
                    if newValue.count > ChatbotViewModel.maxMessageLength {
                        text = String(newValue.prefix(ChatbotViewModel.maxMessageLength))
                    }
                }

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSendDisabled ? Color(.systemGray) : .white)
                    .frame(width: 30, height: 30)
                    .background(
                        isSendDisabled ? Color(.systemGray5) : Color.accentColor,
                        in: Circle()
                    )
            }
            .disabled(isSendDisabled)
            .padding(.bottom, 2)
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    VStack(spacing: 20) {
        ChatInputBar(
            text: $text,
            isSending: false,
            attachedDefect: nil,
            onRemoveAttachment: {},
            onAttach: {},
            onSend: {}
        )
        ChatInputBar(
            text: $text,
            isSending: false,
            attachedDefect: ChatSelectableDefect(
                id: 1, type: .scratch, severity: .low,
                location: "복도 바닥 타일", roomName: "부서진 원흥", imageURL: nil
            ),
            onRemoveAttachment: {},
            onAttach: {},
            onSend: {}
        )
    }
    .padding(16)
}
