//
//  AnalysisLoadingView.swift
//  RoomLog
//
//  Created by minkyo on 5/23/26.
//

import SwiftUI

/// AI 분석 대기 중 공통 로딩 UI
/// 상단에 커스텀 콘텐츠(3D 이미지 등)를 넣고, 하단은 로딩 placeholder를 표시
struct AnalysisLoadingView<TopContent: View>: View {
    let message: String
    let placeholderCount: Int
    @ViewBuilder let topContent: () -> TopContent

    init(
        message: String = "AI가 분석하고 있습니다...",
        placeholderCount: Int = 3,
        @ViewBuilder topContent: @escaping () -> TopContent
    ) {
        self.message = message
        self.placeholderCount = placeholderCount
        self.topContent = topContent
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                topContent()

                VStack(spacing: 16) {
                    ProgressView()
                    Text(message)
                        .font(.medium, 14)
                        .foregroundStyle(Color.blueGray400)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 12) {
                    Text("감지된 하자")
                        .font(.semibold, 20)
                        .foregroundStyle(Color.neutral800)

                    ForEach(0..<placeholderCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blueGray50)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(370.0 / 100.0, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    AnalysisLoadingView {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.blueGray50)
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 10, contentMode: .fit)
            .overlay {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.blueGray300)
            }
    }
}
