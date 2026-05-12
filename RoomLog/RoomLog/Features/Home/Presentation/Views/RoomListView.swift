//
//  RoomListView.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import SwiftUI

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
        static let deleteTitle = "방 삭제"
        static let deleteMessage = "이 방을 삭제하시겠어요?\n관련된 스캔 데이터도 함께 삭제됩니다."
        static let deleteConfirm = "삭제"
        static let cancel = "취소"
    }

    // MARK: - Properties

    @Environment(\.di) private var di
    @State private var viewModel: RoomListViewModel

    init(houseId: Int, houseName: String, provider: HomeUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: RoomListViewModel(houseId: houseId, houseName: houseName, provider: provider)
        )
    }

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    // MARK: - Body

    var body: some View {
        content(viewModel: viewModel)
            .tint(.accent)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.fetchRooms() }
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

            scanButton
        }
        .navigationTitle(viewModel.houseName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.rooms.isEmpty {
                    Button(viewModel.isEditing ? Strings.doneButton : Strings.editButton) {
                        withAnimation { viewModel.isEditing.toggle() }
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
        HStack(spacing: Layout.rowSpacing) {
            thumbnailView(url: room.thumbnailURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.semibold, 16)
                    .foregroundStyle(.neutral800)

                if let date = room.recentScanDate {
                    Text(Self.displayDateFormatter.string(from: date))
                        .font(.medium, 14)
                        .foregroundStyle(.blueGray300)
                }
            }

            Spacer()

            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private func thumbnailView(url: String?) -> some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
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

    // MARK: - Scan Button

    private var scanButton: some View {
        BottomCTAButton {
            pathStore.homePath.append(.home(.scan))
        } label: {
            HStack(spacing: 8) {
                Image(.scan)
                Text(Strings.scanButton)
                    .font(.semibold, 16)
            }
        }
    }

    // MARK: - Date Formatter

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()
}
