//
//  RoomDetailViewPreviews.swift
//  RoomLog
//
//  Created by 김도연 on 5/13/26.
//

#if DEBUG
import SwiftUI

private let sampleRoom = RoomDetail(
    id: 1,
    name: "거실",
    address: nil,
    moveInDate: nil,
    moveOutDate: nil,
    thumbnailURL: nil,
    fileURL: nil,
    createdAt: Date(),
    latestScan: ScanDetail(scanId: 1, status: "COMPLETED", createdAt: Date())
)

#Preview("스캔 데이터 없음") {
    NavigationStack {
        RoomDetailView(preview: sampleRoom)
    }
}

#Preview("에러 상태") {
    NavigationStack {
        RoomDetailView(
            preview: sampleRoom,
            errorMessage: "네트워크 연결에 실패했습니다"
        )
    }
}

#Preview("PLY 뷰어") {
    NavigationStack {
        RoomDetailView(
            preview: sampleRoom,
            localPLYURL: URL(fileURLWithPath: "/Users/dodle/Library/Mobile Documents/com~apple~CloudDocs/DGU/2026-1/캡스톤디자인/room.ply")
        )
    }
}
#endif
