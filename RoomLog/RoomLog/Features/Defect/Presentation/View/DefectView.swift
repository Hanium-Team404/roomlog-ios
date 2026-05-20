//
//  DefectView.swift
//  RoomLog
//
//  Created by 송민교 on 4/20/26.
//

import SwiftUI

struct DefectView: View {
    @Environment(\.di) var di
    @State private var viewModel: DefectViewModel

    init(roomId: Int, provider: DefectUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: DefectViewModel(roomId: roomId, provider: provider)
        )
    }

    var body: some View {
        Group {
            if let report = viewModel.report {
                content(report: report)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(viewModel.report.map { "\($0.room.title) 하자" } ?? "하자 점검")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchReport()
        }
    }

    @ViewBuilder
    private func content(report: DefectReport) -> some View {
        let pathStore = di.resolve(PathStore.self)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                imageSection(report: report)
                summarySection(report: report)
                defectListSection(
                    defects: report.defects,
                    onViewAll: {
                        pathStore.defectPath.append(.defect(.defectAllList(
                            roomId: viewModel.roomId,
                            roomName: report.room.title,
                            defects: report.defects
                        )))
                    },
                    onTap: { defect in
                        pathStore.defectPath.append(.defect(.defectListDetail(
                            defect: defect,
                            roomId: viewModel.roomId,
                            roomImageURL: report.imageURL
                        )))
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            bottomButton
        }
    }

    private var bottomButton: some View {
        BottomCTAButton {
            let pathStore = di.resolve(PathStore.self)
            pathStore.defectPath.append(.defect(.repairHistory(roomId: viewModel.roomId)))
        } label: {
            Text("수리 내역 보기")
                .font(.semibold, 17)
        }
    }
}

#Preview {
    let di = DIContainer.configured()
    NavigationStack {
        DefectView(roomId: 1, provider: di.resolve(DefectUseCaseProvider.self))
    }
    .environment(\.di, di)
}

// MARK: - Section 1: 이미지 + 마커
// TODO: - 추후 3d이미지로 불러오기 및 마커 수정 - @minkyo

private extension DefectView {
    @ViewBuilder
    func imageSection(report: DefectReport) -> some View {
        ZStack {
            if let urlString = report.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }

            GeometryReader { geo in
                ForEach(report.defects, id: \.id) { defect in
                    if let x = defect.x, let y = defect.y {
                        VStack(spacing: 2) {
                            Text(defect.type)
                                .font(.semibold, 14)
                            Text(String(format: "%.2f m²", defect.defectArea))
                                .font(.semibold, 14)
                        }
                        .foregroundStyle(Color.neutral800)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                        .position(
                            x: CGFloat(x) * geo.size.width,
                            y: CGFloat(y) * geo.size.height
                        )
                    }
                }
            }
        }
        .frame(height: 262)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var imagePlaceholder: some View {
        Color(.systemGray5)
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Section 2: 요약 정보

private extension DefectView {
    @ViewBuilder
    func summarySection(report: DefectReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("내 RoomLog 정보")
                .font(.semibold, 13)
                .foregroundStyle(Color.blueGray500)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blueGray50, in: RoundedRectangle(cornerRadius: 20))

            Spacer().frame(height: 16)

            HStack(spacing: 0) {
                SummaryStatView(value: "\(report.defectCount)", label: "하자")
                SummaryStatView(value: formattedCost(report.minRepairCost), label: "예상 수리비")
                SummaryStatView(value: String(format: "%.1fm²", report.repairArea), label: "면적")
            }

            Spacer().frame(height: 16)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    func formattedCost(_ cost: Int) -> String {
        let manWon = cost / 10000
        if manWon > 0 { return "\(manWon)만원" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return "\(f.string(from: NSNumber(value: cost)) ?? "\(cost)")원"
    }
}

// MARK: - Section 3: 하자 리스트

private extension DefectView {
    @ViewBuilder
    func defectListSection(
        defects: [DefectReportDetail],
        onViewAll: @escaping () -> Void,
        onTap: @escaping (DefectReportDetail) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("감지된 하자")
                    .font(.semibold, 20)
                    .foregroundStyle(Color.neutral800)
                Spacer()
                Button(action: onViewAll) {
                    HStack(spacing: 4) {
                        Text("전체보기")
                            .font(.semibold, 14)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.mutedBlue)
                }
            }

            ForEach(defects, id: \.id) { defect in
                DefectReportRow(defect: defect)
                    .onTapGesture { onTap(defect) }
            }
        }
    }
}

// MARK: - 요약 스탯 아이템

private struct SummaryStatView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 12) {
            Text(value)
                .font(.semibold, 24)
                .foregroundStyle(.primary)
            Text(label)
                .font(.medium, 16)
                .foregroundStyle(Color.dustyBlue)
        }
        .frame(maxWidth: .infinity)
    }
}

