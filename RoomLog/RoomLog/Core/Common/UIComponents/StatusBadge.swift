//
//  StatusBadge.swift
//  RoomLog
//
//  Created by minkyo on 6/4/26.
//

import SwiftUI

struct StatusBadge: View {
    let label: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
    }
}

// MARK: - Convenience Initializers

extension StatusBadge {
    /// 분석 상태 뱃지
    init(analysisStatus: AnalysisStatus) {
        self.label = analysisStatus.label
        switch analysisStatus {
        case .completed:
            self.foreground = Color.mutedBlue
            self.background = Color.blueGray50
        case .pending:
            self.foreground = .white
            self.background = Color.mutedBlue
        case .failed:
            self.foreground = .white
            self.background = Color(red: 0.89, green: 0.21, blue: 0.22)
        }
    }

    /// 견적 상태 뱃지
    init(estimateStatus: EstimateDisplayStatus) {
        self.label = estimateStatus.label
        switch estimateStatus {
        case .inProgress:
            self.foreground = .white
            self.background = Color.mutedBlue
        case .completed:
            self.foreground = Color.mutedBlue
            self.background = Color.blueGray50
        }
    }
}
