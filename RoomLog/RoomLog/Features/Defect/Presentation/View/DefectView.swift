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
    private let skipAutoLoad: Bool

    init(roomId: Int, provider: DefectUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: DefectViewModel(roomId: roomId, provider: provider)
        )
        self.skipAutoLoad = false
    }

    #if DEBUG
    init(viewModel: DefectViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.skipAutoLoad = true
    }
    #endif

    var body: some View {
        Group {
            switch viewModel.phase {
            case .loading:
                ProgressView()
            case .polling:
                if let report = viewModel.report {
                    pollingContent(report: report)
                } else {
                    ProgressView()
                }
            case .completed:
                if let report = viewModel.report {
                    content(report: report)
                }
            case .failed(let message):
                errorView(message: message)
            }
        }
        .navigationTitle(viewModel.report.map { "\($0.room.title) 하자" } ?? "하자 점검")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !skipAutoLoad, viewModel.phase == .loading else { return }
            await viewModel.loadOrAnalyze()
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

    // MARK: - Polling Content (3D 이미지만 표시 + 나머지 로딩)

    @ViewBuilder
    private func pollingContent(report: DefectReport) -> some View {
        AnalysisLoadingView(message: "AI가 하자를 분석하고 있습니다...") {
            imageSection(report: report)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.blueGray300)
            Text("분석에 실패했습니다")
                .font(.semibold, 18)
                .foregroundStyle(Color.neutral800)
            Text(message)
                .font(.medium, 14)
                .foregroundStyle(Color.blueGray400)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.startAnalysis() }
            } label: {
                Text("다시 시도")
                    .font(.semibold, 16)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



// MARK: - Section 1: 3D PLY 뷰어 + 마커

private extension DefectView {
    @ViewBuilder
    func imageSection(report: DefectReport) -> some View {
        Group {
            if let localURL = viewModel.plyLocalURL {
                PLYSceneView(fileURL: localURL, defects: report.defects)
            } else if report.imageURL != nil {
                ProgressView("3D 모델 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                imagePlaceholder
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            await viewModel.downloadPLYIfNeeded()
        }
    }

    var imagePlaceholder: some View {
        ImagePlaceholder(iconFont: .largeTitle)
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
                            .font(.semibold, 11)
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

#Preview("로딩 상태") {
    let di = DIContainer.configured()
    NavigationStack {
        DefectView(roomId: 1, provider: di.resolve(DefectUseCaseProvider.self))
    }
    .environment(\.di, di)
}

#Preview("하자 분석 완료") {
    let di = DIContainer.configured()
    let vm = DefectViewModel.preview(
        phase: .completed,
        report: PreviewSampleData.defectReport,
        provider: di.resolve(DefectUseCaseProvider.self)
    )
    NavigationStack {
        DefectView(viewModel: vm)
    }
    .environment(\.di, di)
}

#Preview("Polling 상태") {
    let di = DIContainer.configured()
    let vm = DefectViewModel.preview(
        phase: .polling,
        report: PreviewSampleData.pollingReport,
        provider: di.resolve(DefectUseCaseProvider.self)
    )
    NavigationStack {
        DefectView(viewModel: vm)
    }
    .environment(\.di, di)
}

#Preview("실패 상태") {
    let di = DIContainer.configured()
    let vm = DefectViewModel.preview(
        phase: .failed("서버에서 분석에 실패했습니다"),
        report: nil,
        provider: di.resolve(DefectUseCaseProvider.self)
    )
    NavigationStack {
        DefectView(viewModel: vm)
    }
    .environment(\.di, di)
}
