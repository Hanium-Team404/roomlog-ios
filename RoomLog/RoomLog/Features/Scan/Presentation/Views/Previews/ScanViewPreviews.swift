//
//  ScanViewPreviews.swift
//  RoomLog
//
//  Created by 김도연 on 5/13/26.
//

#if DEBUG
import SwiftUI

#Preview("대기 (idle)") {
    NavigationStack {
        ScanView(preview: .idle)
    }
}

#Preview("녹화 중") {
    NavigationStack {
        ScanView(preview: .recording)
    }
}

#endif
