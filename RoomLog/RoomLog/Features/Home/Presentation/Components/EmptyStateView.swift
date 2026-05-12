//
//  EmptyStateView.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import SwiftUI

struct EmptyStateView: View {

    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 8) {
            Image(.roof)
            Text(title)
                .font(.semibold, 18)
                .foregroundStyle(.deepNavy)
            Text(description)
                .font(.regular, 14)
                .foregroundStyle(.blueGray500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
