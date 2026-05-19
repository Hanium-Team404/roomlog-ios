//
//  SeverityBadge.swift
//  RoomLog
//
//  Created by minkyo on 5/17/26.
//

import SwiftUI

struct SeverityBadge: View {
    let severity: Severity
    var size: BadgeSize = .small

    enum BadgeSize {
        case small, medium
    }

    var body: some View {
        Text(severity.label)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(severity.color)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(severity.color.opacity(0.2), in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var fontSize: CGFloat {
        switch size {
        case .small: 12
        case .medium: 16
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: 8
        case .medium: 12
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: 4
        case .medium: 6
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: 7
        case .medium: 12
        }
    }
}

// MARK: - Severity Display

extension Severity {
    var label: String {
        switch self {
        case .high: "높음"
        case .medium: "보통"
        case .low: "낮음"
        }
    }

    var color: Color {
        switch self {
        case .high: Color(red: 0.89, green: 0.21, blue: 0.22)
        case .medium: Color(red: 0.94, green: 0.55, blue: 0.12)
        case .low: Color(red: 0.21, green: 0.38, blue: 0.89)
        }
    }
}
