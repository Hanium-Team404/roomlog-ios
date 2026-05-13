//
//  RoomListViewPreviews.swift
//  RoomLog
//
//  Created by 김도연 on 5/13/26.
//

#if DEBUG
import SwiftUI

#Preview("방 목록") {
    NavigationStack {
        RoomListView(
            houseId: 1,
            houseName: "미리보기 집",
            provider: MockHomeUseCaseProvider(rooms: PreviewSampleData.rooms)
        )
    }
    .environment(\.di, .preview())
}

#Preview("빈 방 목록") {
    NavigationStack {
        RoomListView(
            houseId: 1,
            houseName: "미리보기 집",
            provider: MockHomeUseCaseProvider()
        )
    }
    .environment(\.di, .preview())
}

#Preview("스캔 처리 중") {
    let manager = ScanProcessingManager()
    return NavigationStack {
        RoomListView(
            houseId: 1,
            houseName: "미리보기 집",
            provider: MockHomeUseCaseProvider(rooms: PreviewSampleData.rooms)
        )
    }
    .environment(\.di, .preview(processingManager: manager))
    .onAppear {
        manager.setActiveScan(.init(scanId: 1, houseId: 1, phase: .polling))
    }
}

#Preview("스캔 완료") {
    let manager = ScanProcessingManager()
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("preview.ply")
    return NavigationStack {
        RoomListView(
            houseId: 1,
            houseName: "미리보기 집",
            provider: MockHomeUseCaseProvider(rooms: PreviewSampleData.rooms)
        )
    }
    .environment(\.di, .preview(processingManager: manager))
    .onAppear {
        manager.setActiveScan(.init(scanId: 1, houseId: 1, phase: .completed(fileURL: tempURL)))
    }
}

#Preview("스캔 실패") {
    let manager = ScanProcessingManager()
    return NavigationStack {
        RoomListView(
            houseId: 1,
            houseName: "미리보기 집",
            provider: MockHomeUseCaseProvider(rooms: PreviewSampleData.rooms)
        )
    }
    .environment(\.di, .preview(processingManager: manager))
    .onAppear {
        manager.setActiveScan(.init(scanId: 1, houseId: 1, phase: .failed("서버에서 스캔 처리에 실패했습니다")))
    }
}
#endif
