//
//  InfoChip.swift
//  RoomLog
//
//  Created by minkyo on 6/4/26.
//

import SwiftUI

struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.blueGray400)
            Text(text)
                .font(.medium, 13)
                .foregroundStyle(Color.blueGray600)
        }
    }
}
