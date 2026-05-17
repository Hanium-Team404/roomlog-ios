//
//  HouseImageView.swift
//  RoomLog
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI

struct HouseImageView: View {

    let houseId: Int
    let name: String
    var spacing: CGFloat = 4
    var nameFontSize: Int = 18

    private var imageResource: ImageResource {
        switch houseId % 2 {
        case 0: .home
        default : .home1
        }
    }

    var body: some View {
        VStack(spacing: spacing) {
            Text(name)
                .font(.medium, nameFontSize)
                .foregroundStyle(.neutral500)
            Image(imageResource)
                .resizable()
                .scaledToFit()
        }
    }
}
