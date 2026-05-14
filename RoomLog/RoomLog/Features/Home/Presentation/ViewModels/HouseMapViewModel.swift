//
//  HouseMapViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

@Observable
final class HouseMapViewModel {

    // MARK: - Constants

    static let canvasSize: CGFloat = 1500
    static let houseImageWidth: CGFloat = 200

    // MARK: - State

    private(set) var positions: [Int: CGPoint] = HousePositionStore.load()
    private(set) var draggingHouseId: Int?
    private var dragTouchOffset: CGPoint?

    // MARK: - Position

    func positionFor(house: House, index: Int) -> CGPoint {
        positions[house.houseId] ?? Self.defaultPosition(index: index)
    }

    func centerTarget(houses: [House], mainHouseId: Int?) -> CGPoint {
        let targetIndex: Int
        if let mainId = mainHouseId,
           let idx = houses.firstIndex(where: { $0.houseId == mainId }) {
            targetIndex = idx
        } else {
            targetIndex = 0
        }
        return positionFor(house: houses[targetIndex], index: targetIndex)
    }

    // MARK: - Drag Handling

    /// 드래그 시작 시 터치 지점 근처의 집을 찾아 드래그 모드 진입. 집을 찾으면 해당 houseId 반환.
    func dragBegan(at canvasPoint: CGPoint, houses: [House]) -> Int? {
        let hitRadius = Self.houseImageWidth / 2
        for (index, house) in houses.enumerated() {
            let housePos = positionFor(house: house, index: index)
            let dx = canvasPoint.x - housePos.x
            let dy = canvasPoint.y - housePos.y
            if abs(dx) < hitRadius && abs(dy) < hitRadius {
                dragTouchOffset = CGPoint(x: dx, y: dy)
                draggingHouseId = house.houseId
                return house.houseId
            }
        }
        return nil
    }

    func dragChanged(to canvasPoint: CGPoint) {
        guard let houseId = draggingHouseId, let offset = dragTouchOffset else { return }
        positions[houseId] = CGPoint(
            x: canvasPoint.x - offset.x,
            y: canvasPoint.y - offset.y
        )
    }

    func dragEnded() {
        if let houseId = draggingHouseId, let finalPos = positions[houseId] {
            let margin: CGFloat = 100
            let clamped = CGPoint(
                x: min(max(finalPos.x, margin), Self.canvasSize - margin),
                y: min(max(finalPos.y, margin), Self.canvasSize - margin)
            )
            positions[houseId] = clamped
            HousePositionStore.save(positions)
        }
        draggingHouseId = nil
        dragTouchOffset = nil
    }

    // MARK: - Default Spiral Positioning

    private static func defaultPosition(index: Int) -> CGPoint {
        let center = canvasSize / 2
        let (gridCol, gridRow) = spiralOffset(index)
        let cellW: CGFloat = 240
        let cellH: CGFloat = 120
        let x = center + CGFloat(gridCol) * cellW + CGFloat(gridRow) * cellW / 2
        let y = center + CGFloat(gridRow) * cellH / 2
        return CGPoint(x: x, y: y)
    }

    private static func spiralOffset(_ index: Int) -> (Int, Int) {
        if index == 0 { return (0, 0) }

        let dx = [1, 0, -1, 0]
        let dy = [0, 1, 0, -1]

        var x = 0, y = 0
        var direction = 0
        var stepsInDirection = 1
        var stepsTaken = 0
        var turnCount = 0

        for _ in 0..<index {
            x += dx[direction]
            y += dy[direction]
            stepsTaken += 1
            if stepsTaken == stepsInDirection {
                stepsTaken = 0
                direction = (direction + 1) % 4
                turnCount += 1
                if turnCount % 2 == 0 {
                    stepsInDirection += 1
                }
            }
        }
        return (x, y)
    }
}

// MARK: - Local Position Storage

enum HousePositionStore {
    private static let key = "house_positions"

    static func save(_ positions: [Int: CGPoint]) {
        let dict = positions.reduce(into: [String: [CGFloat]]()) { result, pair in
            result[String(pair.key)] = [pair.value.x, pair.value.y]
        }
        UserDefaults.standard.set(dict, forKey: key)
    }

    static func load() -> [Int: CGPoint] {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: [CGFloat]] else {
            return [:]
        }
        return dict.reduce(into: [Int: CGPoint]()) { result, pair in
            if let id = Int(pair.key), pair.value.count == 2 {
                result[id] = CGPoint(x: pair.value[0], y: pair.value[1])
            }
        }
    }
}
