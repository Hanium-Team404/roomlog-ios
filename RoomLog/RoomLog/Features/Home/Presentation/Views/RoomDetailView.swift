//
//  RoomDetailView.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import SwiftUI

struct RoomDetailView: View {

    @State private var viewModel: RoomDetailViewModel

    init(roomId: Int, provider: HomeUseCaseProvider, scanRepository: ScanRepositoryProtocol) {
        self._viewModel = .init(
            wrappedValue: RoomDetailViewModel(roomId: roomId, provider: provider, scanRepository: scanRepository)
        )
    }

    #if DEBUG
    init(preview roomDetail: RoomDetail?, localPLYURL: URL? = nil, errorMessage: String? = nil) {
        self._viewModel = .init(
            wrappedValue: RoomDetailViewModel(preview: roomDetail, localPLYURL: localPLYURL, errorMessage: errorMessage)
        )
    }
    #endif

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.roomDetail == nil {
                ProgressView("방 정보를 불러오는 중...")
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if viewModel.isDownloading {
                ProgressView("3D 파일을 다운로드하는 중...")
            } else if let plyURL = viewModel.localPLYURL {
                PLYSceneView(fileURL: plyURL)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                emptyView
            }
        }
        .navigationTitle(viewModel.roomDetail?.name ?? "방 상세")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundStyle(.blueGray300)
            Text("스캔 데이터가 없습니다")
                .font(.medium, 16)
                .foregroundStyle(.blueGray500)
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.blueGray300)
            Text(message)
                .font(.medium, 14)
                .foregroundStyle(.blueGray500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("다시 시도")
                    .font(.semibold, 16)
                    .foregroundStyle(.accent)
            }
        }
    }
}
