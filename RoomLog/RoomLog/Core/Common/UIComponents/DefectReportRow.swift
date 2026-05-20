//
//  DefectReportRow.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import SwiftUI

struct DefectReportRow: View {
    let defect: DefectReportDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(defect.type)
                    .font(.semibold, 16)
                    .foregroundStyle(Color.neutral800)
                SeverityBadge(severity: defect.severity)
            }

            Text(defect.location)
                .font(.medium, 14)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                chip(formattedCost)
                chip(formattedArea)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.medium, 14)
            .foregroundStyle(Color.neutral700)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 7))
    }

    private var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let s = formatter.string(from: NSNumber(value: defect.repairCost)) ?? "\(defect.repairCost)"
        return "₩ \(s)"
    }

    private var formattedArea: String {
        String(format: "%.2f m²", defect.defectArea)
    }
}

#Preview {
    DefectReportRow(defect: PreviewSampleData.defects[0])
        .padding(16)
}
