//
//  ModelLoadFailurePlaceholder.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/13/26.
//

import SwiftUI

/// 3D 모델을 내려받지 못했을 때 뷰어 자리에 띄우는 안내.
/// 옛 캐시를 대신 보여주면 새 결과를 옛 메시 위에 그리게 되므로 실패를 그대로 드러낸다.
struct ModelLoadFailurePlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cube.transparent")
                .font(.largeTitle)
                .foregroundStyle(Color.blueGray300)
            Text("3D 모델을 불러오지 못했습니다")
                .font(.medium, 14)
                .foregroundStyle(Color.blueGray400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blueGray50)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ModelLoadFailurePlaceholder()
        .aspectRatio(4/3, contentMode: .fit)
        .padding()
}
