//
//  IsometricGridView.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import SwiftUI

struct IsometricGridView: View {

    // MARK: - Constants

    private enum Layout {
        static let cellWidth: CGFloat = 120
        static let cellHeight: CGFloat = 60
        static let lineWidth: CGFloat = 0.7
        static let lineOpacity: Double = 0.4
        /// 캔버스 밖까지 그리드를 채우기 위한 여유 셀 수
        static let overflowPadding: Int = 40
    }

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            var path = Path()

            let cols = Int(size.width / Layout.cellWidth) + Layout.overflowPadding
            let rows = Int(size.height / Layout.cellHeight) + Layout.overflowPadding
            let offsetX = size.width / 2
            let offsetY = size.height / 2

            for row in -rows...rows {
                for col in -cols...cols {
                    // 각 마름모의 중심점
                    let cx = offsetX + CGFloat(col) * Layout.cellWidth + (CGFloat(row) * Layout.cellWidth / 2)
                    let cy = offsetY + CGFloat(row) * Layout.cellHeight / 2

                    // 마름모 4꼭짓점: 상, 우, 하, 좌
                    let top    = CGPoint(x: cx,                        y: cy - Layout.cellHeight / 2)
                    let right  = CGPoint(x: cx + Layout.cellWidth / 2, y: cy)
                    let bottom = CGPoint(x: cx,                        y: cy + Layout.cellHeight / 2)
                    let left   = CGPoint(x: cx - Layout.cellWidth / 2, y: cy)

                    path.move(to: top)
                    path.addLine(to: right)
                    path.addLine(to: bottom)
                    path.addLine(to: left)
                    path.closeSubpath()
                }
            }

            context.stroke(path, with: .color(.gray.opacity(Layout.lineOpacity)), lineWidth: Layout.lineWidth)
        }
    }
}
