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

#Preview {
    ToastView {
        HStack(spacing: 0) {
            Text("집을 추가한 뒤 ").foregroundStyle(.neutral600)
            Text("Viewer").foregroundStyle(.dustyBlue)
            Text("를 사용하실 수 있습니다").foregroundStyle(.neutral600)
        }
        .font(.medium, 14)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
    .padding(.horizontal, 24)
}

