//
//  ComparisonResultView.swift
//  RoomLog
//
//  Created by 송민교 on 5/21/26.
//

import SwiftUI

struct ComparisonResultView: View {
    let moveInScanId: Int
    let moveOutScanId: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                imagePlaceholder
                differenceSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("비교 결과")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Image Placeholder

private extension ComparisonResultView {
    var imagePlaceholder: some View {
        ZStack {
            Color.blueGray50
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.blueGray300)
                        Text("3D 모델 영역")
                            .font(.medium, 14)
                            .foregroundStyle(Color.blueGray300)
                    }
                }

            GeometryReader { geo in
                ForEach(PreviewSampleData.defects.prefix(3), id: \.id) { defect in
                    if let x = defect.x, let y = defect.y {
                        VStack(spacing: 2) {
                            Text(defect.type.displayName)
                                .font(.semibold, 12)
                            Text(String(format: "%.2f m²", defect.defectArea))
                                .font(.medium, 11)
                        }
                        .foregroundStyle(Color.neutral800)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                        .position(
                            x: CGFloat(x) * geo.size.width,
                            y: CGFloat(y) * geo.size.height
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 10, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Difference Section

private extension ComparisonResultView {
    var differenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("주요 차이점")
                    .font(.semibold, 20)
                    .foregroundStyle(Color.neutral800)
                Text("\(PreviewSampleData.defects.count)")
                    .font(.semibold, 20)
                    .foregroundStyle(Color.accentColor)
            }

            ForEach(PreviewSampleData.defects, id: \.id) { defect in
                DefectReportRow(defect: defect)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ComparisonResultView(moveInScanId: 1, moveOutScanId: 4)
    }
}
