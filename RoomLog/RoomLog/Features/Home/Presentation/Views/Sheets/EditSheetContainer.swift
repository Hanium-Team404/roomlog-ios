//
//  EditSheetContainer.swift
//  RoomLog
//
//  Created by 김도연 on 5/23/26.
//

import SwiftUI

/// 수정/생성 시트 공통 컨테이너. 콘텐츠 높이를 측정해 시트 높이를 자동으로 맞춘다.
struct EditSheetContainer<Content: View>: View {

    let title: String
    var saveButtonTitle: String = "저장"
    let isSaving: Bool
    let isValid: Bool
    let onSave: () -> Void
    @ViewBuilder let content: () -> Content

    /// 내비게이션 바 + 드래그 인디케이터가 차지하는 높이
    private static var chromeHeight: CGFloat { 60 }

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            // ScrollView 안의 콘텐츠는 detent와 무관하게 이상적 높이로 배치되므로 안정적으로 측정된다.
            // ScrollView를 각 시트(콘텐츠) 쪽에 두면 detent ↔ 측정값이 서로를 참조해
            // 시트 높이가 0에 수렴하므로, 컨테이너가 직접 소유한다.
            ScrollView {
                VStack(spacing: 0) {
                    content()
                        .padding()
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newValue in
                    contentHeight = newValue
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(saveButtonTitle)
                                .font(.semibold, 17)
                                // 명시적 색은 disabled 시 SwiftUI의 자동 흐림 처리를 덮어쓰므로
                                // 비활성 상태를 직접 표현한다.
                                .foregroundStyle(isValid ? Color.mutedBlue : Color.mutedBlue.opacity(0.35))
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
        .presentationDetents([.height(contentHeight + Self.chromeHeight)])
        .presentationDragIndicator(.visible)
    }
}

