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
        static let houseSpacing: CGFloat = 4
        static let houseNameFontSize: Int = 18
        /// 화면 가장자리에서 auto-scroll이 시작되는 거리 (캔버스 좌표)
        static let edgeScrollMargin: CGFloat = 120
        /// auto-scroll 최대 속도 (pt/tick, 캔버스 좌표)
        static let edgeScrollMaxSpeed: CGFloat = 4
    }

    private enum Zoom {
        static let minScale: CGFloat = 0.7
        static let maxScale: CGFloat = 2.0
    }

    private enum Strings {
        static let emptyTitle = "저장된 집이 없어요"
        static let emptyBody = "+버튼을 클릭하여\n집을 추가해보세요!"
    }

    // MARK: - Properties

    let houses: [House]
    var mainHouseId: Int?
    var namespace: Namespace.ID
    var recenterTrigger: Int = 0
    var onHouseTap: (House) -> Void

    @State private var viewModel = HouseMapViewModel()
    @State private var isScrollEnabled: Bool = true
    @State private var scrollProxy = ScrollProxy()
    @State private var autoScrollTimer: Timer?
    @State private var hasCenteredOnce: Bool = false

    // MARK: - Body

    var body: some View {
        if houses.isEmpty {
            ZStack {
                IsometricGridView()
                    .ignoresSafeArea()

                EmptyStateView(title: Strings.emptyTitle, description: Strings.emptyBody)
            }
        } else {
            ZoomableScrollView(
                contentSize: CGSize(
                    width: HouseMapViewModel.canvasSize,
                    height: HouseMapViewModel.canvasSize
                ),
                minZoom: Zoom.minScale,
                maxZoom: Zoom.maxScale,
                isScrollEnabled: $isScrollEnabled,
                scrollProxy: scrollProxy,
                onLongPressDrag: { canvasPoint, phase in
                    handleDrag(canvasPoint: canvasPoint, phase: phase)
                }
            ) {
                ZStack {
                    IsometricGridView()
                        .frame(
                            width: HouseMapViewModel.canvasSize,
                            height: HouseMapViewModel.canvasSize
                        )

                    ForEach(Array(houses.enumerated()), id: \.element.houseId) { index, house in
                        let pos = viewModel.positionFor(house: house, index: index)
                        HouseImageView(
                            houseColor: house.houseColor,
                            floorColor: house.floorColor,
                            name: house.name,
                            spacing: Layout.houseSpacing,
                            nameFontSize: Layout.houseNameFontSize
                        )
                        .frame(width: HouseMapViewModel.houseImageWidth)
                        .scaleEffect(viewModel.draggingHouseId == house.houseId ? 1.1 : 1.0)
                        .shadow(
                            color: viewModel.draggingHouseId == house.houseId
                                ? .black.opacity(0.2) : .clear,
                            radius: 10, y: 5
                        )
                        .matchedTransitionSource(id: house.houseId, in: namespace)
                        .position(pos)
                        .onTapGesture {
                            if viewModel.draggingHouseId == nil {
                                onHouseTap(house)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                if !hasCenteredOnce {
                    scrollToCenter()
                    hasCenteredOnce = true
                }
            }
            .onChange(of: houses) { oldHouses, newHouses in
                if newHouses.count > oldHouses.count {
                    let oldIds = Set(oldHouses.map { $0.houseId })
                    guard let added = newHouses.first(where: { !oldIds.contains($0.houseId) }),
                          let index = newHouses.firstIndex(where: { $0.houseId == added.houseId }) else {
                        return
                    }
                    scrollToCenter(target: viewModel.positionFor(house: added, index: index))
                } else if newHouses.count < oldHouses.count {
                    scrollToCenter()
                }
            }
            .onChange(of: recenterTrigger) {
                scrollToCenter()
            }
            .onDisappear {
                stopAutoScroll()
            }
        }
    }

    // MARK: - Drag → ViewModel Bridge

    private func handleDrag(canvasPoint: CGPoint, phase: LongPressDragPhase) {
        switch phase {
        case .began:
            if let houseId = viewModel.dragBegan(at: canvasPoint, houses: houses) {
                isScrollEnabled = false
                startAutoScroll(houseId: houseId)
            }
        case .changed:
            viewModel.dragChanged(to: canvasPoint)
        case .ended:
            stopAutoScroll()
            viewModel.dragEnded()
            isScrollEnabled = true
        }
    }

    // MARK: - Scroll

    private func scrollToCenter(target: CGPoint? = nil) {
        let point = target ?? viewModel.centerTarget(houses: houses, mainHouseId: mainHouseId)
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            scrollProxy.scrollTo(canvasPoint: point)
        }
    }

    // MARK: - Auto-Scroll

    private func startAutoScroll(houseId: Int) {
        stopAutoScroll()
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard let housePos = viewModel.positions[houseId] else { return }
            let visible = scrollProxy.visibleRect
            guard visible.width > 0 else { return }

            let margin = Layout.edgeScrollMargin
            let maxSpeed = Layout.edgeScrollMaxSpeed

            func edgeRatio(_ distance: CGFloat) -> CGFloat {
                guard distance < margin else { return 0 }
                return (1 - distance / margin)
            }

            let leftDist = housePos.x - visible.minX
            let rightDist = visible.maxX - housePos.x
            let topDist = housePos.y - visible.minY
            let bottomDist = visible.maxY - housePos.y

            let dx = -edgeRatio(leftDist) * maxSpeed + edgeRatio(rightDist) * maxSpeed
            let dy = -edgeRatio(topDist) * maxSpeed + edgeRatio(bottomDist) * maxSpeed

            if abs(dx) > 0.1 || abs(dy) > 0.1 {
                scrollProxy.adjustOffset(by: CGVector(dx: dx, dy: dy))
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
}
