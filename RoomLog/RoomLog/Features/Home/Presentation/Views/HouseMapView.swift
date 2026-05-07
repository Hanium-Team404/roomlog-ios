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
        static let emptyStateSpacing: CGFloat = 4
        static let emptyTitleFontSize: Int = 18
        static let emptyBodyFontSize: Int = 16
        static let houseNameFontSize: Int = 18
    }

    private enum Zoom {
        static let minScale: CGFloat = 0.7
        static let maxScale: CGFloat = 2.0
    }

    private enum Strings {
        static let emptyTitle = "저장된 집이 없어요"
        static let emptyBody1 = "+버튼을 클릭하여"
        static let emptyBody2 = "집을 추가해보세요!"
    }

    // MARK: - Properties

    let houses: [House]
    var onHouseTap: (House) -> Void

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
                
                if houses.isEmpty {
                    VStack(alignment: .center, spacing: Layout.emptyStateSpacing) {
                        Image(.roof)
                        Text(Strings.emptyTitle)
                            .font(.semibold, Layout.emptyTitleFontSize)
                            .foregroundStyle(.deepNavy)
                        Text(Strings.emptyBody1)
                            .font(.regular, Layout.emptyBodyFontSize)
                            .foregroundStyle(.blueGray500)
                        Text(Strings.emptyBody2)
                            .font(.regular, Layout.emptyBodyFontSize)
                            .foregroundStyle(.blueGray500)
                    }
                } else {
                    ForEach(houses, id: \.houseId) { house in
                        VStack(spacing: Layout.houseSpacing) {
                            Text(house.name)
                                .font(.medium, Layout.houseNameFontSize)
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
            }
            .frame(width: Layout.canvasSize, height: Layout.canvasSize)
        }
        .disabled(houses.isEmpty)
        .ignoresSafeArea()
    }
}
