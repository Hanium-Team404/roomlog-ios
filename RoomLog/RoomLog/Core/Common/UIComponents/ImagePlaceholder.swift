//
//  ImagePlaceholder.swift
//  RoomLog
//
//  Created by minkyo on 6/2/26.
//

import SwiftUI

struct ImagePlaceholder: View {
    var systemImage: String = "photo"
    var iconFont: Font = .title3

    var body: some View {
        Color(.systemGray5)
            .overlay {
                Image(systemName: systemImage)
                    .font(iconFont)
                    .foregroundStyle(.tertiary)
            }
    }
}
