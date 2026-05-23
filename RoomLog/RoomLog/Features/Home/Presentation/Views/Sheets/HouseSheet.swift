//
//  HouseSheet.swift
//  RoomLog
//
//  Created by 김도연 on 5/23/26.
//

import SwiftUI

struct HouseSheet: View {

    let house: House?
    let onSave: (String, String?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var address: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isEditing: Bool { house != nil }

    init(house: House? = nil, onSave: @escaping (String, String?) async throws -> Void) {
        self.house = house
        self.onSave = onSave
        self._name = State(initialValue: house?.name ?? "")
        self._address = State(initialValue: house?.address ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        EditSheetContainer(
            title: isEditing ? "집 정보 수정" : "새 집 추가",
            detent: .height(280),
            isSaving: isSaving,
            isValid: isValid,
            onSave: { save() }
        ) {
            HStack {
                Text("집 이름")
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("예: 망고의 집", text: $name)
                    .font(.medium, 16)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Text("주소")
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("예: 서울시 강남구 테헤란로 123", text: $address)
                    .font(.medium, 16)
                    .multilineTextAlignment(.trailing)
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
                let trimmedAddress = address.trimmingCharacters(in: .whitespaces)
                try await onSave(
                    name.trimmingCharacters(in: .whitespaces),
                    trimmedAddress.isEmpty ? nil : trimmedAddress
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
