//
//  RoomEditSheet.swift
//  RoomLog
//
//  Created by 김도연 on 5/23/26.
//

import SwiftUI

struct RoomEditSheet: View {

    let roomDetail: RoomDetail
    let onSave: @MainActor (String, Date, Date?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var moveInDate: Date
    @State private var moveOutDate: Date
    @State private var hasMoveOutDate: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    /// 시트를 연 시점의 값. 변경 여부 판단 기준이므로 `roomDetail`의 nil 날짜를 채운 기본값까지 포함한다
    private let initialMoveInDate: Date
    private let initialMoveOutDate: Date

    init(roomDetail: RoomDetail, onSave: @escaping @MainActor (String, Date, Date?) async throws -> Void) {
        self.roomDetail = roomDetail
        self.onSave = onSave
        let moveInDate = roomDetail.moveInDate ?? Date()
        let moveOutDate = roomDetail.moveOutDate ?? Date()
        self.initialMoveInDate = moveInDate
        self.initialMoveOutDate = moveOutDate
        self._name = State(initialValue: roomDetail.name)
        self._moveInDate = State(initialValue: moveInDate)
        self._moveOutDate = State(initialValue: moveOutDate)
        self._hasMoveOutDate = State(initialValue: roomDetail.moveOutDate != nil)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 날짜는 일 단위로만 편집하므로 같은 날이면 변경으로 보지 않는다
    private var hasChanges: Bool {
        let calendar = Calendar.current
        if name != roomDetail.name { return true }
        if !calendar.isDate(moveInDate, inSameDayAs: initialMoveInDate) { return true }
        if hasMoveOutDate != (roomDetail.moveOutDate != nil) { return true }
        return hasMoveOutDate && !calendar.isDate(moveOutDate, inSameDayAs: initialMoveOutDate)
    }

    var body: some View {
        EditSheetContainer(
            title: "방 정보 수정",
            isSaving: isSaving,
            isValid: isValid,
            hasChanges: hasChanges,
            onSave: { save() }
        ) {
            VStack(spacing: 16) {
                CapsuleFieldRow(title: "방 이름") {
                    TextField("예: 거실, 안방", text: $name)
                        .font(.medium, 16)
                        .multilineTextAlignment(.trailing)
                }

                CapsuleFieldRow(title: "입주일") {
                    DatePicker("", selection: $moveInDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                CapsuleFieldRow(title: "퇴거일") {
                    Toggle("", isOn: $hasMoveOutDate.animation(.easeInOut(duration: 0.2)))
                        .labelsHidden()
                        .tint(.accent)
                }

                if hasMoveOutDate {
                    CapsuleFieldRow(title: "퇴거 날짜") {
                        DatePicker("", selection: $moveOutDate, in: moveInDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.regular, 13)
                        .foregroundStyle(.red)
                }
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
