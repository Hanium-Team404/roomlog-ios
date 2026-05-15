//
//  KakaoMapView.swift
//  RoomLog
//
//  Created by 송민교 on 5/13/26.
//

import SwiftUI
import UIKit
import KakaoMapsSDK

struct KakaoMapView: UIViewRepresentable {
    let shops: [RepairShop]
    let selectedShop: RepairShop?
    let onTapShop: (RepairShop) -> Void

    func makeUIView(context: Context) -> KMViewContainer {
        let container = KMViewContainer()
        context.coordinator.attach(to: container)
        return container
    }

    func updateUIView(_ uiView: KMViewContainer, context: Context) {
        context.coordinator.update(shops: shops, selected: selectedShop)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTapShop: onTapShop)
    }

    static func dismantleUIView(_ uiView: KMViewContainer, coordinator: Coordinator) {
        coordinator.detach()
    }
}

extension KakaoMapView {
    final class Coordinator: NSObject, MapControllerDelegate, KakaoMapEventDelegate {
        private weak var container: KMViewContainer?
        private var controller: KMController?
        private var mapReady = false
        private var didFitCamera = false
        private var pendingShops: [RepairShop] = []
        private var pendingSelected: RepairShop?
        private var poiByID: [String: Poi] = [:]
        private var lastSelectedID: String?
        private let onTapShop: (RepairShop) -> Void

        private let viewName = "shopMapView"
        private let layerID = "shopPoiLayer"
        private let unselectedStyleID = "shopPoiStyle"
        private let selectedStyleID = "shopPoiStyleSelected"

        init(onTapShop: @escaping (RepairShop) -> Void) {
            self.onTapShop = onTapShop
            super.init()
        }

        func attach(to container: KMViewContainer) {
            self.container = container
            let controller = KMController(viewContainer: container)
            controller.delegate = self
            controller.prepareEngine()
            self.controller = controller
        }

        func detach() {
            controller?.pauseEngine()
            controller?.resetEngine()
            controller = nil
        }

        func update(shops: [RepairShop], selected: RepairShop?) {
            pendingShops = shops
            pendingSelected = selected
            guard mapReady,
                  let kakaoMap = controller?.getView(viewName) as? KakaoMap
            else { return }
            applyShops(on: kakaoMap)
        }

        // MARK: - MapControllerDelegate

        func addViews() {
            let defaultPosition = MapPoint(longitude: 126.978365, latitude: 37.566691)
            let info = MapviewInfo(
                viewName: viewName,
                defaultPosition: defaultPosition,
                defaultLevel: 13
            )
            controller?.addView(info)
        }

        func authenticationSucceeded() {
            controller?.activateEngine()
        }

        func authenticationFailed(_ errorCode: Int, desc: String) {
            print("[KakaoMap] auth failed: \(errorCode) — \(desc)")
        }

        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
            guard let kakaoMap = controller?.getView(viewName) as? KakaoMap else { return }
            kakaoMap.eventDelegate = self
            mapReady = true
            setupPoiStyles(on: kakaoMap)
            applyShops(on: kakaoMap)
        }

        func addViewFailed(_ viewName: String, viewInfoName: String) {
            print("[KakaoMap] addView failed: \(viewName)")
        }

        func containerDidResized(_ size: CGSize) {
            controller?.getView(viewName)?.viewRect = CGRect(origin: .zero, size: size)
        }

        // MARK: - KakaoMapEventDelegate

        func poiDidTapped(kakaoMap: KakaoMap, layerID: String, poiID: String, position: MapPoint) {
            guard let shop = pendingShops.first(where: { $0.externalId == poiID }) else { return }
            onTapShop(shop)
        }

        // MARK: - POI(Point of Interest)

        private func setupPoiStyles(on map: KakaoMap) {
            let manager = map.getLabelManager()

            let layerOption = LabelLayerOptions(
                layerID: layerID,
                competitionType: .none,
                competitionUnit: .symbolFirst,
                orderType: .rank,
                zOrder: 5000
            )
            _ = manager.addLabelLayer(option: layerOption)

            let unselectedSymbol = makePinImage(selected: false)
            let selectedSymbol = makePinImage(selected: true)

            let unselectedIconStyle = PoiIconStyle(symbol: unselectedSymbol, anchorPoint: CGPoint(x: 0.5, y: 1.0))
            let selectedIconStyle = PoiIconStyle(symbol: selectedSymbol, anchorPoint: CGPoint(x: 0.5, y: 1.0))

            let unselectedStyle = PoiStyle(styleID: unselectedStyleID, styles: [
                PerLevelPoiStyle(iconStyle: unselectedIconStyle, level: 0)
            ])
            let selectedStyle = PoiStyle(styleID: selectedStyleID, styles: [
                PerLevelPoiStyle(iconStyle: selectedIconStyle, level: 0)
            ])
            manager.addPoiStyle(unselectedStyle)
            manager.addPoiStyle(selectedStyle)
        }

        private func applyShops(on map: KakaoMap) {
            let manager = map.getLabelManager()
            guard let layer = manager.getLabelLayer(layerID: layerID) else { return }

            let selectedID = pendingSelected?.externalId

            layer.clearAllItems()
            poiByID.removeAll()

            for shop in pendingShops {
                let isSelected = (shop.externalId == selectedID)
                let position = MapPoint(longitude: shop.longitude, latitude: shop.latitude)
                let options = PoiOptions(styleID: isSelected ? selectedStyleID : unselectedStyleID, poiID: shop.externalId)
                options.rank = 0
                options.clickable = true
                if let poi = layer.addPoi(option: options, at: position) {
                    poi.show()
                    poiByID[shop.externalId] = poi
                }
            }

            if selectedID != lastSelectedID {
                lastSelectedID = selectedID
                if let selected = pendingSelected {
                    let target = MapPoint(longitude: selected.longitude, latitude: selected.latitude)
                    let update = CameraUpdate.make(target: target, zoomLevel: 14, mapView: map)
                    map.moveCamera(update)
                }
            }

            if !didFitCamera, selectedID == nil, let first = pendingShops.first {
                didFitCamera = true
                let target = MapPoint(longitude: first.longitude, latitude: first.latitude)
                let update = CameraUpdate.make(target: target, zoomLevel: 14, mapView: map)
                map.moveCamera(update)
            }
        }

        private func makePinImage(selected: Bool) -> UIImage {
            UIImage(named: selected ? "pin_blue" : "pin_gray") ?? UIImage()
        }
    }
}
