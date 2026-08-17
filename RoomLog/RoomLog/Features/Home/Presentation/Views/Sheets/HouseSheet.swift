//
//  HouseSheet.swift
//  RoomLog
//
//  Created by 김도연 on 5/23/26.
//

import SwiftUI

struct HouseSheet: View {

    let house: House?
    let addressUpdates: (() -> AsyncStream<String>)?
    let onSave: (String, String, HouseColor, FloorColor) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var address: String
    @State private var houseColor: HouseColor
    @State private var floorColor: FloorColor
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isEditing: Bool { house != nil }

    init(
        house: House? = nil,
        addressUpdates: (() -> AsyncStream<String>)? = nil,
        onSave: @escaping (String, String, HouseColor, FloorColor) async throws -> Void
    ) {
        self.house = house
        self.addressUpdates = addressUpdates
        self.onSave = onSave
        self._name = State(initialValue: house?.name ?? "")
        self._address = State(initialValue: house?.address ?? "")
        self._houseColor = State(initialValue: house?.houseColor ?? .fallback)
        self._floorColor = State(initialValue: house?.floorColor ?? .fallback)
    }

    /// 이름과 주소는 모두 필수 입력이다.
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        EditSheetContainer(
            title: isEditing ? "집 정보 수정" : "새 집 추가",
            saveButtonTitle: isEditing ? "저장" : "추가",
            isSaving: isSaving,
            isValid: isValid,
            onSave: { save() }
        ) {
            VStack(spacing: 16) {
                HouseIconView(houseColor: houseColor, floorColor: floorColor)
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)

                colorPickerRow(title: "지붕 색상", items: HouseColor.allCases, displayColor: \.displayColor, selection: $houseColor)

                colorPickerRow(title: "바닥 색상", items: FloorColor.allCases, displayColor: \.displayColor, selection: $floorColor)

                capsuleField(title: "집 이름", placeholder: "예: 망고의 집", text: $name)

                capsuleField(title: "주소", placeholder: "예: 서울시 강남구 테헤란로 123", text: $address)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.regular, 13)
                        .foregroundStyle(.red)
                }
            }
        }
        .task { await prefillAddressIfNeeded() }
    }

    /// 새 집 추가 시 현재 위치 기반으로 주소 필드를 미리 채운다.
    /// 첫 픽스로 즉시 채우고 더 정확한 주소가 오면 갱신하되, 사용자가 직접 입력을 시작하면 멈춘다.
    /// 권한 거부·위치 실패 시 조용히 빈 칸을 유지한다.
    private func prefillAddressIfNeeded() async {
        guard !isEditing, address.isEmpty, let addressUpdates else { return }
        var lastPrefilled = ""
        for await currentAddress in addressUpdates() {
            // 필드가 마지막 프리필 값 그대로일 때만 갱신 — 사용자가 수정(삭제 포함)했으면 멈춘다
            guard address == lastPrefilled else { return }
            address = currentAddress
            lastPrefilled = currentAddress
        }
    }

    private func colorPickerRow<Item: Hashable>(
        title: String,
        items: [Item],
        displayColor: @escaping (Item) -> Color,
        selection: Binding<Item>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.medium, 14)
                .foregroundStyle(.neutral800)
            HStack(spacing: 0) {
                ForEach(items, id: \.self) { item in
                    let isSelected = selection.wrappedValue == item
                    Button {
                        selection.wrappedValue = item
                    } label: {
                        Circle()
                            .fill(displayColor(item))
                            .frame(width: 34, height: 34)
                            .overlay {
                                // 선택된 색상은 자기 색으로 바깥 링 표시
                                Circle()
                                    .stroke(displayColor(item), lineWidth: 2.5)
                                    .padding(-5)
                                    .opacity(isSelected ? 1 : 0)
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func capsuleField(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
                .font(.medium, 14)
                .foregroundStyle(.secondary)
            Spacer()
            TextField(placeholder, text: text)
                .font(.medium, 16)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Capsule().fill(Color(.systemGray6)))
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await onSave(
                    name.trimmingCharacters(in: .whitespaces),
                    address.trimmingCharacters(in: .whitespaces),
                    houseColor,
                    floorColor
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
