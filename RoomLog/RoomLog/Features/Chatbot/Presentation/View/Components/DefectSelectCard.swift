//
//  DefectSelectCard.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

/// 첫 진입 시 대화 영역에 노출되는 "등록된 하자에서 선택하기" 카드
struct DefectSelectCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("등록된 하자에서 선택하기")
                        .font(.semibold, 15)
                        .foregroundStyle(Color.neutral800)
                    Text("내가 등록한 하자 목록에서 선택해 해결 방법을 알아봐요")
                        .font(.medium, 12)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
    }
}

#Preview {
    DefectSelectCard {}
        .padding(16)
}
