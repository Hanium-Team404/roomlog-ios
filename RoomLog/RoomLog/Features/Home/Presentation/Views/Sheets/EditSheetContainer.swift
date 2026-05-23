//
//  EditSheetContainer.swift
//  RoomLog
//
//  Created by 김도연 on 5/23/26.
//

import SwiftUI

struct EditSheetContainer<Content: View>: View {

    let title: String
    let detent: PresentationDetent
    let isSaving: Bool
    let isValid: Bool
    let onSave: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content()
                    .padding()

                Spacer()

                BottomCTAButton {
                    onSave()
                } label: {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("저장")
                            .font(.semibold, 17)
                    }
                }
                .disabled(!isValid || isSaving)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([detent])
        .presentationDragIndicator(.visible)
    }
}
