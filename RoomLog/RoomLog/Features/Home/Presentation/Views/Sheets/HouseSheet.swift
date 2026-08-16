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
        .task { await prefillAddressIfNeeded() }
    }

    /// 새 집 추가 시 현재 위치 기반으로 주소 필드를 미리 채운다.
    /// 첫 픽스로 즉시 채우고 더 정확한 주소가 오면 갱신하되, 사용자가 직접 입력을 시작하면 멈춘다.
    /// 권한 거부·위치 실패 시 조용히 빈 칸을 유지한다.
    private func prefillAddressIfNeeded() async {
        guard !isEditing, address.isEmpty else { return }
        var lastPrefilled = ""
        for await currentAddress in CurrentAddressProvider().addressUpdates() {
            // 필드가 마지막 프리필 값 그대로일 때만 갱신 — 사용자가 수정(삭제 포함)했으면 멈춘다
            guard address == lastPrefilled else { return }
            address = currentAddress
            lastPrefilled = currentAddress
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
