//
//  DefectView.swift
//  RoomLog
//
//  Created by 송민교 on 4/20/26.
//

import SwiftUI

struct DefectView: View {
    let roomId: Int
    @Environment(\.di) var di
    @State private var viewModel: DefectViewModel?

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.isLoading {
                    ProgressView()
                } else if let report = viewModel.report {
                    content(report: report)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("하자 점검")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                let useCase = di.resolve(UseCaseProvider.self).makeGetDefectReportUseCase()
                viewModel = DefectViewModel(roomId: roomId, useCase: useCase)
            }
            Task { await viewModel?.fetchReport() }
        }
    }

    @ViewBuilder
    private func content(report: DefectReport) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                imageSection(report: report)
                summarySection(report: report)
                defectListSection(defects: report.defects)
            }
            .padding()
        }
    }
}

// MARK: - Section 1: 이미지 + 마커

private extension DefectView {
    @ViewBuilder
    func imageSection(report: DefectReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("나의 RoomLog")
                .font(.title2)
                .fontWeight(.bold)

            ZStack(alignment: .topLeading) {
                // TODO: 실제 이미지 URL 연동 시 AsyncImage로 교체
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 260)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }

                GeometryReader { geo in
                    ForEach(report.defects, id: \.id) { defect in
                        if let x = defect.x, let y = defect.y {
                            Text(defect.type)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .glassEffect(.regular, in: Capsule())
                                .position(
                                    x: CGFloat(x) * geo.size.width,
                                    y: CGFloat(y) * geo.size.height
                                )
                        }
                    }
                }
                .frame(height: 260)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Section 2: 요약 정보

private extension DefectView {
    @ViewBuilder
    func summarySection(report: DefectReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("나의 RoomLog 예상 수리 비용")
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 0) {
                SummaryStatView(title: "하자 개수", value: "\(report.defectCount)개")
                Divider().frame(height: 40)
                SummaryStatView(title: "최소 수리비", value: "\(report.minRepairCost.formatted())원")
                Divider().frame(height: 40)
                SummaryStatView(title: "견적 총합", value: String(format: "%.1fm²", report.repairArea))
            }
            .padding()
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Section 3: 하자 리스트

private extension DefectView {
    @ViewBuilder
    func defectListSection(defects: [DefectReportDetail]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("감지된 하자")
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))

            ForEach(defects, id: \.id) { defect in
                DefectReportRow(defect: defect)
            }
        }
    }
}

// MARK: - 요약 스탯 아이템

private struct SummaryStatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 하자 리스트 Row

private struct DefectReportRow: View {
    let defect: DefectReportDetail

    var body: some View {
        HStack(spacing: 12) {
            severityIndicator
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(defect.type)
                        .font(.body)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(defect.repairCost.formatted())원")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text(defect.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(defect.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    private var severityIndicator: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(defect.severity.color)
            .frame(width: 4, height: 50)
    }
}

private extension Severity {
    var color: Color {
        switch self {
        case .high: .red
        case .medium: .orange
        case .low: .yellow
        }
    }
}
