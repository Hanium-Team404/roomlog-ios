//
//  DefectSelectSheet.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI
import NukeUI

/// 대표 집에 등록된 하자 목록에서 하나를 선택하는 sheet (C04).
/// 행을 탭하면 즉시 닫히고 선택한 하자가 입력창 위에 첨부된다.
struct DefectSelectSheet: View {
    let viewModel: ChatbotViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("등록된 하자")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("닫기") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await viewModel.loadDefects()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isDefectListLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.defectListLoadFailed {
            VStack(spacing: 12) {
                Text("하자 목록을 불러오지 못했어요")
                    .font(.medium, 15)
                    .foregroundStyle(.secondary)
                Button("다시 시도") {
                    Task { await viewModel.loadDefects() }
                }
                .font(.semibold, 15)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.selectableDefects.isEmpty {
            ContentUnavailableView(
                "등록된 하자가 없어요",
                systemImage: "checkmark.seal",
                description: Text("하자 분석을 완료하면 여기에서 선택할 수 있어요")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.selectableDefects) { defect in
                        Button {
                            viewModel.attach(defect)
                        } label: {
                            ChatDefectRow(defect: defect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Row

private struct ChatDefectRow: View {
    let defect: ChatSelectableDefect

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 64, height: 64)
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(defect.type.displayName)
                        .font(.semibold, 16)
                        .foregroundStyle(Color.neutral800)
                    SeverityBadge(severity: defect.severity)
                }

                Text(locationText)
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(.white, in: .rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .contentShape(.rect)
    }

    private var locationText: String {
        defect.roomName.isEmpty ? defect.location : "\(defect.roomName) · \(defect.location)"
    }

    private var thumbnail: some View {
        Group {
            if let urlString = defect.imageURL, let url = URL(string: urlString) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        ImagePlaceholder()
                    }
                }
            } else {
                ImagePlaceholder()
            }
        }
    }
}
