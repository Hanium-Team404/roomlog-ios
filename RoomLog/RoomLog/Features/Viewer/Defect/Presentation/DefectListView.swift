//
//  DefectListView.swift
//  RoomLog
//
//  Created by 송민교 on 4/20/26.
//

import SwiftUI

struct DefectListView: View {
    @Environment(\.di) var di
    @State private var viewModel: DefectListViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("하자 점검")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if viewModel == nil {
                let useCase = di.resolve(DefectUseCaseProvider.self).makeGetDefectRoomDataUseCase()
                viewModel = DefectListViewModel(useCase: useCase)
            }
            Task { await viewModel?.fetchItems() }
        }
    }

    @ViewBuilder
    private func content(viewModel: DefectListViewModel) -> some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            ProgressView()
        } else if viewModel.items.isEmpty {
            ContentUnavailableView("하자 점검 내역이 없습니다", systemImage: "magnifyingglass")
        } else {
            let pathStore = di.resolve(PathStore.self)
            List(viewModel.items, id: \.id) { item in
                DefectListRow(item: item) {
                    pathStore.defectPath.append(.defect(.defectListMain(roomId: item.id)))
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - 하자 List들

private struct DefectListRow: View {
    let item: DefectRoomData
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "house.fill")
                    .foregroundStyle(.secondary)
            }
    }
}
