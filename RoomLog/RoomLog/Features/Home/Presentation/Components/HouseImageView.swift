//
//  HouseImageView.swift
//  RoomLog
//
//  Created by 김도연 on 5/17/26.
//

import SwiftUI

/// 집 건물 + 바닥 에셋을 겹쳐 하나의 집 아이콘으로 합성하는 뷰.
/// 색상이 nil이면(색상 정보가 없는 기존 집) 기본 색상으로 표시한다.
struct HouseIconView: View {

    var houseColor: HouseColor?
    var floorColor: FloorColor?

    /// 피그마 원본 크기 기준 배치 상수 (바닥 187×113, 집 150.64×130.52).
    /// 집 밑면 다이아몬드를 바닥판 윗면 중앙에 맞춘 값.
    private enum Metrics {
        static let canvasWidth: CGFloat = 187
        static let canvasHeight: CGFloat = 148.7
        static let houseWidth: CGFloat = 150.64
        static let floorTopOffset: CGFloat = 35.7
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Metrics.canvasWidth
            ZStack(alignment: .top) {
                Image((floorColor ?? .fallback).imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.canvasWidth * scale)
                    .offset(y: Metrics.floorTopOffset * scale)
                Image((houseColor ?? .fallback).imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.houseWidth * scale)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .aspectRatio(Metrics.canvasWidth / Metrics.canvasHeight, contentMode: .fit)
    }
}

struct HouseImageView: View {

    let houseColor: HouseColor?
    let floorColor: FloorColor?
    let name: String
    var spacing: CGFloat = 4
    var nameFontSize: Int = 18

    var body: some View {
        VStack(spacing: spacing) {
            Text(name)
                .font(.medium, nameFontSize)
                .foregroundStyle(.neutral500)
            HouseIconView(houseColor: houseColor, floorColor: floorColor)
        }
    }
}

// MARK: - 색상 → 에셋/피커 표시색 매핑

extension HouseColor {
    var imageResource: ImageResource {
        switch self {
        case .blue: .houseBodyBlue
        case .beige: .houseBodyBeige
        case .terracotta: .houseBodyTerracotta
        case .olive: .houseBodyOlive
        case .navy: .houseBodyNavy
        }
    }

    /// 색상 선택 피커에 표시할 대표 색 (지붕 색)
    var displayColor: Color {
        switch self {
        case .blue: .houseBlue
        case .beige: .houseBeige
        case .terracotta: .houseTerracotta
        case .olive: .houseOlive
        case .navy: .houseNavy
        }
    }
}

extension FloorColor {
    var imageResource: ImageResource {
        switch self {
        case .beige: .houseFloorBeige
        case .blueGray: .houseFloorBlueGray
        case .peach: .houseFloorPeach
        case .pink: .houseFloorPink
        case .gray: .houseFloorGray
        }
    }

    /// 색상 선택 피커에 표시할 대표 색
    var displayColor: Color {
        switch self {
        case .beige: .floorBeige
        case .blueGray: .floorBlueGray
        case .peach: .floorPeach
        case .pink: .floorPink
        case .gray: .floorGray
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        HouseIconView(houseColor: .blue, floorColor: .beige)
            .frame(width: 160)
        HouseIconView(houseColor: .terracotta, floorColor: .blueGray)
            .frame(width: 160)
    }
    .padding()
}
