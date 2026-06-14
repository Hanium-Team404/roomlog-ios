//
//  ViewerView.swift
//  RoomLog
//
//  Created by 송민교 on 4/20/26.
//

import SwiftUI
import NukeUI

struct ViewerView: View {
    @Environment(\.di) var di
    @State private var viewModel: ViewerViewModel?

    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                menuCards(pathStore: pathStore)
                recentSection(pathStore: pathStore)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
            }
            ToolbarItem(placement: .topBarTrailing) {
                houseDropdown
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ViewerViewModel(
                    homeProvider: di.resolve(HomeUseCaseProvider.self),
                    homeState: di.resolve(HomeState.self)
                )
            }
            Task {
                await viewModel?.fetchHouses()
                await viewModel?.fetchRooms()
            }
        }
    }
}

// MARK: - House Dropdown

private extension ViewerView {
    var houseDropdown: some View {
        Menu {
            ForEach(viewModel?.houses ?? []) { house in
                Button {
                    viewModel?.selectedHouse = house
                    Task { await viewModel?.fetchRooms() }
                } label: {
                    HStack {
                        Text(house.name)
                        if viewModel?.selectedHouse?.id == house.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel?.selectedHouse != nil ? "\(viewModel!.selectedHouseDisplayName)" : "집 선택")
                    .font(.medium, 16)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(Color.neutral800)
        }
    }
}

// MARK: - Menu Cards

private extension ViewerView {
    func menuCards(pathStore: PathStore) -> some View {
        VStack(spacing: 20) {
            defectCard(pathStore: pathStore)
            compareCard(pathStore: pathStore)
        }
        .frame(maxWidth: .infinity)
    }

    func defectCard(pathStore: PathStore) -> some View {
        Image("viewer_defect")
            .resizable()
            .scaledToFit()
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("하자 점검")
                        .font(.bold, 24)
                        .foregroundStyle(.white)
                    Text("내 방의 하자 정보를\n점검하고 관리해요")
                        .font(.medium, 16)
                        .foregroundStyle(Color.cloudDancer)
                        .lineSpacing(6)
                    Circle()
                        .fill(.white)
                        .frame(width: 49, height: 49)
                        .overlay {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(red: 0.545, green: 0.451, blue: 0.408))
                        }
                        .padding(.top, 8)
                }
                .padding(.leading, 29)
                .padding(.top, 32)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let houseId = viewModel?.selectedHouse?.id {
                    pathStore.defectPath.append(.defect(.defectList(houseId: houseId)))
                }
            }
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
    }

    func compareCard(pathStore: PathStore) -> some View {
        Image("viewer_compare")
            .resizable()
            .scaledToFit()
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("내 방 비교")
                        .font(.bold, 24)
                        .foregroundStyle(Color.deepNavy)
                    Text("입주 전/후 방 상태를\n비교해보세요")
                        .font(.medium, 16)
                        .foregroundStyle(Color.dustyBlue)
                        .lineSpacing(6)
                    Circle()
                        .fill(Color(red: 0.79, green: 0.87, blue: 0.92))
                        .frame(width: 49, height: 49)
                        .overlay {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.deepNavy)
                        }
                        .padding(.top, 8)
                }
                .padding(.leading, 29)
                .padding(.top, 32)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                pathStore.defectPath.append(.defect(.comparisonHistory))
            }
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 최근 점검 목록

private extension ViewerView {
    func recentSection(pathStore: PathStore) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("최근 점검 목록")
                    .font(.semibold, 20)
                    .foregroundStyle(Color.neutral800)
                Spacer()
                Button {
                    if let houseId = viewModel?.selectedHouse?.id {
                        pathStore.defectPath.append(.defect(.defectList(houseId: houseId)))
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("전체보기")
                            .font(.semibold, 14)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.mutedBlue)
                }
            }

            recentListCard(pathStore: pathStore)
        }
    }

    @ViewBuilder
    func recentListCard(pathStore: PathStore) -> some View {
        if let viewModel, !viewModel.rooms.isEmpty {
            VStack(spacing: 16) {
                ForEach(Array(viewModel.rooms.prefix(3).enumerated()), id: \.element.id) { index, room in
                    VStack(spacing: 16) {
                        RecentRoomRow(room: room) {
                            pathStore.defectPath.append(.defect(.defectListMain(roomId: room.id)))
                        }
                        if index < min(viewModel.rooms.count, 3) - 1 {
                            Divider()
                        }
                    }
                }
            }
            .padding(24)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        } else if viewModel?.isLoading == true {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
}

// MARK: - 최근 점검 Row

private struct RecentRoomRow: View {
    let room: RoomSummary
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            thumbnailView
            VStack(alignment: .leading, spacing: 16) {
                Text(room.name)
                    .font(.semibold, 16)
                    .foregroundStyle(Color.neutral800)
                Text(room.recentScanDate?.toShortDisplayString() ?? "-")
                    .font(.medium, 14)
                    .foregroundStyle(Color.blueGray300)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var thumbnailView: some View {
        Group {
            if let urlString = room.thumbnailURL, let url = URL(string: urlString) {
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
        .frame(width: 85, height: 85)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
        ViewerView()
    }
    .environment(\.di, DIContainer.configured())
}
