//
//  BottomCTAButton.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import SwiftUI

struct BottomCTAButton<Label: View>: View {

    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 57)
        }
        .glassEffect(.regular.interactive().tint(.accent), in: .rect(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
