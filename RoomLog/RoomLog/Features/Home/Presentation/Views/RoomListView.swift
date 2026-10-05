//
//  RoomListView.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import SwiftUI
import NukeUI

struct RoomListView: View {

    // MARK: - Constants

    private enum Layout {
        static let thumbnailSize: CGFloat = 85
        static let thumbnailRadius: CGFloat = 10
        static let rowSpacing: CGFloat = 16
    }

    private enum Strings {
        static let editButton = "편집"
        static let doneButton = "완료"
        static let emptyTitle = "아직 스캔한 방이 없어요"
        static let emptyBody = "3D 스캔하기 버튼을 눌러\n방을 추가해보세요!"
        static let scanButton = "3D 스캔하기"
        static let unsupportedDevice = "LiDAR 탑재 기기에서만 스캔할 수 있어요"
        static let deleteTitle = "방 삭제"
        static let deleteMessage = "이 방을 삭제하시겠어요?\n관련된 스캔 데이터도 함께 삭제됩니다."
        static let deleteConfirm = "삭제"
        static let cancel = "취소"
    }

    // MARK: - Properties

    @Environment(\.di) private var di
    @State private var viewModel: RoomListViewModel
    @State private var showProcessingStatus: Bool = false

    init(houseId: Int, houseName: String, provider: HomeUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: RoomListViewModel(houseId: houseId, houseName: houseName, provider: provider)
        )
    }

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    private var processingManager: ScanProcessingManager {
        di.resolve(ScanProcessingManager.self)
    }

    // MARK: - Body

    var body: some View {
        content(viewModel: viewModel)
            .tint(.accent)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.fetchRooms() }
            .onAppear { openRequestedScanStatus() }
            .onChange(of: pathStore.scanStatusRequest) { openRequestedScanStatus() }
    }

    /// 완료 알림으로 이 집의 스캔 상태 시트가 요청됐으면 연다
    /// 스택 중간에 같은 집의 방 목록이 남아 있을 수 있으므로 맨 위 화면일 때만 처리한다 —
    /// 아니면 탭 루트가 스택을 교체하는 동안 사라질 뷰가 요청을 먼저 소비해 버린다
    private func openRequestedScanStatus() {
        guard pathStore.scanStatusRequest == viewModel.houseId,
              case .home(.roomList(let shownHouseId, _)) = pathStore.homePath.last,
              shownHouseId == viewModel.houseId else { return }
        pathStore.scanStatusRequest = nil
        // 알림 이후 스캔을 이미 저장·취소했다면 열 시트가 없다
        guard processingManager.activeScan?.houseId == viewModel.houseId else { return }
        showProcessingStatus = true
    }

    // MARK: - Content

    @ViewBuilder
    private func content(viewModel: RoomListViewModel) -> some View {
        ZStack(alignment: .bottom) {
            if viewModel.isLoading && viewModel.rooms.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.rooms.isEmpty {
                emptyStateView
            } else {
                roomList(viewModel: viewModel)
            }

            bottomAction
        }
        .navigationTitle(viewModel.houseName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.rooms.isEmpty {
                    Button {
                        withAnimation { viewModel.isEditing.toggle() }
                    } label: {
                        Text(viewModel.isEditing ? Strings.doneButton : Strings.editButton)
                            .font(.medium, 16)
                    }
                }
            }
        }
        .alert(
            Strings.deleteTitle,
            isPresented: Binding(
                get: { viewModel.roomToDelete != nil },
                set: { if !$0 { viewModel.roomToDelete = nil } }
            )
        ) {
            Button(Strings.cancel, role: .cancel) {
                viewModel.roomToDelete = nil
            }
            Button(Strings.deleteConfirm, role: .destructive) {
                if let room = viewModel.roomToDelete {
                    Task { await viewModel.deleteRoom(room) }
                }
            }
        } message: {
            Text(Strings.deleteMessage)
        }
    }

    // MARK: - Room List

    @ViewBuilder
    private func roomList(viewModel: RoomListViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.rooms.enumerated()), id: \.element.id) { index, room in
                    VStack(spacing: 0) {
                        roomRow(room: room, isEditing: viewModel.isEditing) {
                            viewModel.roomToDelete = room
                        }

                        if index < viewModel.rooms.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 89)
        }
    }

    // MARK: - Room Row

    @ViewBuilder
    private func roomRow(room: RoomSummary, isEditing: Bool, onDelete: @escaping () -> Void) -> some View {
        if isEditing {
            roomRowContent(room: room) {
                Button(action: onDelete) {
                    Label("삭제", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.red)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        } else {
            Button {
                pathStore.homePath.append(.home(.roomDetail(roomId: room.id)))
            } label: {
                roomRowContent(room: room) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.blueGray300)
                }
            }
        }
    }

    @ViewBuilder
    private func roomRowContent<Trailing: View>(room: RoomSummary, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: Layout.rowSpacing) {
            thumbnailView(url: room.thumbnailURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.semibold, 16)
                    .foregroundStyle(.neutral800)

                if let date = room.recentScanDate {
                    Text(date.toShortDisplayString())
                        .font(.medium, 14)
                        .foregroundStyle(.blueGray300)
                }
            }

            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private func thumbnailView(url: String?) -> some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            LazyImage(url: imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    thumbnailPlaceholder
                }
            }
            .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
            .clipShape(RoundedRectangle(cornerRadius: Layout.thumbnailRadius))
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: Layout.thumbnailRadius)
            .fill(Color(.systemGray5))
            .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
            .overlay {
                Image(systemName: "house.fill")
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(title: Strings.emptyTitle, description: Strings.emptyBody)
    }

    // MARK: - Bottom Action

    @ViewBuilder
    private var bottomAction: some View {
        if let active = processingManager.activeScan, active.houseId == viewModel.houseId {
            BottomCTAButton {
                showProcessingStatus = true
            } label: {
                HStack(spacing: 8) {
                    switch active.phase {
                    case .zipping, .uploading, .polling:
                        ProgressView()
                            .tint(.cloudDancer)
                        Text("스캔 처리 중...")
                            .font(.semibold, 16)
                    case .completed:
                        Image(systemName: "checkmark.circle.fill")
                        Text("스캔 완료! 탭하여 확인")
                            .font(.semibold, 16)
                    case .failed:
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("스캔 실패")
                            .font(.semibold, 16)
                    }
                }
            }
            .sheet(isPresented: $showProcessingStatus) {
                scanStatusSheet(active: active)
            }
        } else if processingManager.activeScan != nil {
            BottomCTAButton { } label: {
                HStack(spacing: 8) {
                    Image(.scan)
                    Text("다른 집에서 스캔 진행 중")
                        .font(.semibold, 16)
                }
            }
            .disabled(true)
        } else if !ScanViewModel.isDeviceSupported {
            BottomCTAButton { } label: {
                HStack(spacing: 8) {
                    Image(.scan)
                    Text(Strings.unsupportedDevice)
                        .font(.semibold, 16)
                }
            }
            .disabled(true)
        } else {
            BottomCTAButton {
                pathStore.homePath.append(.home(.scan(houseId: viewModel.houseId)))
            } label: {
                HStack(spacing: 8) {
                    Image(.scan)
                    Text(Strings.scanButton)
                        .font(.semibold, 16)
                }
            }
        }
    }

    // MARK: - Scan Status Sheet

    private func scanStatusSheet(active: ScanProcessingManager.ActiveScan) -> some View {
        ScanStatusSheet(
            phase: active.phase,
            onPreview: { fileURL in
                showProcessingStatus = false
                pathStore.homePath.append(.home(.plyPreview(
                    fileURL: fileURL,
                    scanId: active.scanId,
                    houseId: active.houseId
                )))
            },
            onCancel: {
                processingManager.cancel()
                showProcessingStatus = false
            },
            onRetry: processingManager.canRetry ? {
                processingManager.retry()
            } : nil
        )
    }

}
