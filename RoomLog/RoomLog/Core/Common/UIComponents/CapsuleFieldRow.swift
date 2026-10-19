//
//  CapsuleFieldRow.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/18/26.
//

import SwiftUI

struct CapsuleFieldRow<Content: View>: View {

    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(title)
                .font(.medium, 14)
                .foregroundStyle(.secondary)
            Spacer()
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Capsule().fill(Color(.systemGray6)))
    }
}
