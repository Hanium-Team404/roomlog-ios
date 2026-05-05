//
//  HouseMapView.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import SwiftUI

struct HouseMapView: View {

    // MARK: - Constants

    private enum Layout {
        static let canvasSize: CGFloat = 1500
        static let houseImageWidth: CGFloat = 200
        static let houseSpacing: CGFloat = 4
    }

    private enum Zoom {
        static let minScale: CGFloat = 0.7
        static let maxScale: CGFloat = 2.0
    }

    // MARK: - Properties

    var onHouseTap: (House) -> Void

    let houses: [House] = [
        House(houseId: 1, name: "망고의 집", x: 750, y: 750),
        House(houseId: 2, name: "도도의 집", x: 350, y: 750)
    ]

    // MARK: - Body

    var body: some View {
        ZoomableScrollView(
            contentSize: CGSize(width: Layout.canvasSize, height: Layout.canvasSize),
            minZoom: Zoom.minScale,
            maxZoom: Zoom.maxScale
        ) {
            ZStack {
                IsometricGridView()
                    .frame(width: Layout.canvasSize, height: Layout.canvasSize)

                ForEach(houses, id: \.houseId) { house in
                    VStack(spacing: Layout.houseSpacing) {
                        Text(house.name)
                            .font(.medium, 18)
                            .foregroundStyle(.neutral500)
                        Image(.home)
                            .resizable()
                            .scaledToFit()
                            .frame(width: Layout.houseImageWidth)
                    }
                    .onTapGesture {
                        onHouseTap(house)
                    }
                    .position(x: CGFloat(house.x), y: CGFloat(house.y))
                }
            }
            .frame(width: Layout.canvasSize, height: Layout.canvasSize)
        }
        .ignoresSafeArea()
    }
}
