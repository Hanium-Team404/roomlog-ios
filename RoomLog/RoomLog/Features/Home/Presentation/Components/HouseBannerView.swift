//
//  HouseBannerView.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import SwiftUI

struct HouseBannerView: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(.house)
                .resizable()
                .scaledToFit()
                .frame(width: 27)

            Group {
                Text("집을 추가한 뒤 ")
                    .foregroundStyle(.neutral600)
                Text("Viewer")
                    .foregroundStyle(.dustyBlue)
                Text("를 사용하실 수 있습니다")
                    .foregroundStyle(.neutral600)
            }
            .font(.medium, 14)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.blueGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}
