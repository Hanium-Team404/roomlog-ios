//
//  RoomEditSheet.swift
//  RoomLog
//
//  Created by 김도연 on 5/23/26.
//

import SwiftUI

struct RoomEditSheet: View {

    let roomDetail: RoomDetail
    let onSave: (String, Date, Date?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var moveInDate: Date
    @State private var moveOutDate: Date
    @State private var hasMoveOutDate: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(roomDetail: RoomDetail, onSave: @escaping (String, Date, Date?) async throws -> Void) {
        self.roomDetail = roomDetail
        self.onSave = onSave
        self._name = State(initialValue: roomDetail.name)
        self._moveInDate = State(initialValue: roomDetail.moveInDate ?? Date())
        self._moveOutDate = State(initialValue: roomDetail.moveOutDate ?? Date())
        self._hasMoveOutDate = State(initialValue: roomDetail.moveOutDate != nil)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        EditSheetContainer(
            title: "방 정보 수정",
            detent: .medium,
            isSaving: isSaving,
            isValid: isValid,
            onSave: { save() }
        ) {
            HStack {
                Text("방 이름")
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("예: 거실, 안방", text: $name)
                    .font(.medium, 16)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            // 입주일
            HStack {
                Text("입주일")
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $moveInDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            // 퇴거일
            VStack(spacing: 12) {
                HStack {
                    Text("퇴거일")
                        .font(.medium, 14)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Toggle("", isOn: $hasMoveOutDate.animation(.easeInOut(duration: 0.2)))
                        .labelsHidden()
                        .tint(.accent)
                }

                if hasMoveOutDate {
                    HStack {
                        Spacer()
                        DatePicker("", selection: $moveOutDate, in: moveInDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            if let errorMessage {
                Text(errorMessage)
                    .font(.regular, 13)
                    .foregroundStyle(.red)
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await onSave(
                    name.trimmingCharacters(in: .whitespaces),
                    moveInDate,
                    hasMoveOutDate ? moveOutDate : nil
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
