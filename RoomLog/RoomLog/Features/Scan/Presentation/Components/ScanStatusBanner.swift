//
//  ScanStatusBanner.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/17/26.
//

import SwiftUI

/// 스캔 화면 중앙에 뜨는 글래스 배너.
/// 글래스 위라 글자색은 고정하지 않고 `.primary`로 두어 배경 밝기에 맞게 시스템이 고른다.
struct ScanStatusBanner: View {
    let systemImage: String
    let text: LocalizedStringKey

    var body: some View {
        VStack() {
            Image(systemName: systemImage)
                .font(.title2)
                .accessibilityHidden(true)
            Text(text)
                .font(.semibold, 16)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .capsule)
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack(spacing: 12) {
            ScanStatusBanner(systemImage: "move.3d", text: "녹화 버튼을 눌러 스캔을 시작하세요")
            ScanStatusBanner(systemImage: "hand.raised.fill", text: "조금 더 떨어져주세요")
            ScanStatusBanner(systemImage: "exclamationmark.triangle.fill", text: "카메라 오류가 발생해 다시 시작하는 중입니다")
        }
    }
}
#endif
