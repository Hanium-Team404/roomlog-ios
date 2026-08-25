//
//  DefectListView.swift
//  RoomLog
//
//  Created by 송민교 on 4/20/26.
//

import SwiftUI
import NukeUI

struct DefectListView: View {
    @Environment(\.di) var di
    @State private var viewModel: DefectListViewModel

    init(houseId: Int, homeProvider: HomeUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: DefectListViewModel(houseId: houseId, homeProvider: homeProvider)
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                ContentUnavailableView(
                    "하자 점검 내역을 불러오지 못했습니다",
                    systemImage: "wifi.exclamationmark",
                    description: Text(errorMessage)
                )
            } else if viewModel.items.isEmpty {
                ContentUnavailableView("하자 점검 내역이 없습니다", systemImage: "magnifyingglass")
            } else {
                let pathStore = di.resolve(PathStore.self)
                List(viewModel.items, id: \.id) { item in
                    DefectListRow(
                        item: item,
                        isAnalysisCompleted: viewModel.completedRoomIds.contains(item.id)
                    ) {
                        pathStore.defectPath.append(.defect(.defectListMain(roomId: item.id)))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(viewModel.houseName.map { "\($0)의 하자 점검" } ?? "하자 점검")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task { await viewModel.fetchItems() }
        }
    }
}

// MARK: - 하자 List Row

private struct DefectListRow: View {
    let item: RoomSummary
    let isAnalysisCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.semibold, 16)
                        .foregroundStyle(Color.neutral800)
                    statusBadge
                }
                Text(item.recentScanDate?.toShortDisplayString() ?? "-")
                    .font(.medium, 14)
                    .foregroundStyle(Color.blueGray300)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.blueGray300)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var thumbnailView: some View {
        Group {
            if let urlString = item.thumbnailURL, let url = URL(string: urlString) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fit)
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isAnalysisCompleted {
            StatusBadge(analysisStatus: .completed)
        } else {
            StatusBadge(label: "진행 전", foreground: Color.blueGray300, background: Color.blueGray50)
        }
    }

    private var placeholder: some View {
        Color.blueGray50
            .overlay {
                Image(systemName: "house.fill")
                    .foregroundStyle(Color.blueGray300)
            }
    }
}

#Preview {
    NavigationStack {
        DefectListView(houseId: 1, homeProvider: DIContainer.configured().resolve(HomeUseCaseProvider.self))
    }
    .environment(\.di, DIContainer.configured())
}
