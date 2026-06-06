//
//  ComparisonResultView.swift
//  RoomLog
//
//  Created by 송민교 on 5/21/26.
//

import SwiftUI

struct ComparisonResultView: View {
    @Environment(\.di) var di
    @State private var viewModel: ComparisonResultViewModel

    init(moveInRoomId: Int, moveOutRoomId: Int, analysisID: Int? = nil, provider: DefectUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: ComparisonResultViewModel(
                moveInRoomId: moveInRoomId,
                moveOutRoomId: moveOutRoomId,
                analysisID: analysisID,
                provider: provider
            )
        )
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .loading:
                ProgressView()
            case .polling:
                pollingContent
            case .completed:
                if let result = viewModel.result {
                    completedContent(result: result)
                }
            case .failed(let message):
                errorView(message: message)
            }
        }
        .navigationTitle("비교 결과")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadOrAnalyze()
        }
    }
}

// MARK: - Polling Content

private extension ComparisonResultView {
    var pollingContent: some View {
        AnalysisLoadingView(message: "AI가 입주 전/후를 비교하고 있습니다...") {
            plyToggle
            plySection(defects: [])
        }
    }
}

// MARK: - Completed Content

private extension ComparisonResultView {
    func completedContent(result: AnalysisResult) -> some View {
        let pathStore = di.resolve(PathStore.self)
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                plyToggle
                plySection(defects: viewModel.currentDefects)
                summarySection(result: result)
                defectListSection(result: result, pathStore: pathStore)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            BottomCTAButton {
                pathStore.defectPath.append(.defect(.repairHistory(roomId: result.roomId)))
            } label: {
                Text("수리 내역 보기")
                    .font(.semibold, 17)
            }
        }
    }
}

// MARK: - 3D PLY Viewer

private extension ComparisonResultView {
    var plyToggle: some View {
        HStack(spacing: 0) {
            ForEach(ComparisonResultViewModel.PLYMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.plyMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.medium, 14)
                        .foregroundStyle(viewModel.plyMode == mode ? .white : Color.neutral800)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.plyMode == mode ? Color.mutedBlue : Color.clear,
                            in: Capsule()
                        )
                }
            }
        }
        .background(Color.blueGray50, in: Capsule())
    }

    func plySection(defects: [DefectReportDetail]) -> some View {
        Group {
            if let localURL = viewModel.currentPLYURL {
                PLYSceneView(fileURL: localURL, defects: defects)
            } else {
                ProgressView("3D 모델 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            await viewModel.downloadPLYIfNeeded()
        }
    }
}

// MARK: - Summary

private extension ComparisonResultView {
    func summarySection(result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("내 RoomLog 정보")
                .font(.semibold, 13)
                .foregroundStyle(Color.blueGray500)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blueGray50, in: RoundedRectangle(cornerRadius: 20))

            Spacer().frame(height: 16)

            HStack(spacing: 0) {
                SummaryStatView(value: "\(result.defectCount)", label: "하자")
                SummaryStatView(value: result.totalCost.formattedCost, label: "예상 수리비")
                SummaryStatView(value: String(format: "%.1fm²", result.totalArea), label: "면적")
            }

            Spacer().frame(height: 16)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

}

// MARK: - Defect List

private extension ComparisonResultView {
    func defectListSection(result: AnalysisResult, pathStore: PathStore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("감지된 하자")
                    .font(.semibold, 20)
                    .foregroundStyle(Color.neutral800)
                Spacer()
                Button {
                    pathStore.defectPath.append(.defect(.defectAllList(
                        roomId: result.roomId,
                        roomName: "",
                        defects: result.defects
                    )))
                } label: {
                    HStack(spacing: 4) {
                        Text("전체보기")
                            .font(.semibold, 14)
                        Image(systemName: "chevron.right")
                            .font(.semibold, 11)
                    }
                    .foregroundStyle(Color.mutedBlue)
                }
            }

            ForEach(result.defects, id: \.id) { defect in
                DefectReportRow(defect: defect)
                    .onTapGesture {
                        pathStore.defectPath.append(.defect(.defectListDetail(
                            defect: defect,
                            roomId: result.roomId,
                            roomImageURL: result.plyURL
                        )))
                    }
            }
        }
    }
}

// MARK: - Error View

private extension ComparisonResultView {
    func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.blueGray300)
            Text("비교 분석에 실패했습니다")
                .font(.semibold, 18)
                .foregroundStyle(Color.neutral800)
            Text(message)
                .font(.medium, 14)
                .foregroundStyle(Color.blueGray400)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.loadOrAnalyze() }
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

// MARK: - Summary Stat 

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

#Preview {
    let di = DIContainer.configured()
    NavigationStack {
        ComparisonResultView(
            moveInRoomId: 1,
            moveOutRoomId: 2,
            provider: di.resolve(DefectUseCaseProvider.self)
        )
    }
    .environment(\.di, di)
}
