//
//  ToastView.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import SwiftUI

struct ToastView<Label: View>: View {

    @ViewBuilder let label: () -> Label

    var body: some View {
        HStack(spacing: 8) {
            Image(.house)
                .resizable()
                .scaledToFit()
                .frame(width: 27)
            label()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.blueGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}
