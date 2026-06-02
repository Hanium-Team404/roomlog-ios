//
//  SystemToastView.swift
//  RoomLog
//
//  Created by 송민교 on 5/19/26.
//

import SwiftUI

struct SystemToastView<Label: View>: View {
    let systemImage: String

    @ViewBuilder let label: () -> Label

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.mutedBlue)
            label()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.blueGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}
