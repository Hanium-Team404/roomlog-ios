//
//  BottomCTAButton.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import SwiftUI

/// 화면 하단 주요 동작 버튼.
/// 버튼은 `glassEffect`를 직접 씌우지 않고 `glassProminent` 스타일을 쓴다 —
/// 눌림·disabled 외형을 시스템이 처리하므로 `.disabled(_:)`만 걸면 된다
struct BottomCTAButton<Label: View>: View {

    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .bottomCTALabel()
        }
        .bottomCTAContainer()
    }
}

/// `BottomCTAButton`과 같은 외형의 값 기반 네비게이션 링크.
/// 가장 가까운 `NavigationStack`에 push되므로 화면이 어느 탭 스택에 올라가 있든 동작한다
struct BottomCTALink<Label: View>: View {

    let value: NavigationDestination
    @ViewBuilder let label: () -> Label

    var body: some View {
        NavigationLink(value: value) {
            label()
                .bottomCTALabel()
        }
        .bottomCTAContainer()
    }
}

private extension View {
    func bottomCTALabel() -> some View {
        foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
    }

    func bottomCTAContainer() -> some View {
        buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(.accent)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
    }
}
