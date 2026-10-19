//
//  InlineErrorText.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/18/26.
//

import SwiftUI

struct InlineErrorText: View {

    let message: String

    var body: some View {
        Text(message)
            .font(.regular, 13)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}
