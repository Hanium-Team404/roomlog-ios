//
//  ViewerView.swift
//  RoomLog
//
//  Created by 송민교 on 4/20/26.
//

import SwiftUI

struct ViewerView: View {
    @Environment(\.di) var di
    @State private var viewModel: ViewerViewModel?

    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                logoHeader
                menuCards(pathStore: pathStore)
                recentSection(pathStore: pathStore)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if viewModel == nil {
                let useCase = di.resolve(DefectUseCaseProvider.self).makeGetDefectRoomDataUseCase()
                viewModel = ViewerViewModel(useCase: useCase)
            }
            Task { await viewModel?.fetchRooms() }
        }
    }
}

// MARK: - Logo

private extension ViewerView {
    var logoHeader: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(height: 32)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Menu Cards

private extension ViewerView {
    func menuCards(pathStore: PathStore) -> some View {
        VStack(spacing: 0) {
            defectCard(pathStore: pathStore)
            compareCard(pathStore: pathStore)
        }
        .frame(maxWidth: .infinity)
    }

    func defectCard(pathStore: PathStore) -> some View {
        return ZStack {
            Image("viewer_defect")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .layoutPriority(-1)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("하자 점검")
                    .font(.bold, 24)
                    .foregroundStyle(.white)
                Text("내 방의 하자 정보를\n점검하고 관리해요")
                    .font(.medium, 16)
                    .foregroundStyle(Color.cloudDancer)
                    .lineSpacing(6)
                Button {
                    pathStore.defectPath.append(.defect(.defectList))
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 39, height: 39)
                        .overlay {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(red: 0.545, green: 0.451, blue: 0.408))
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 29)
            .padding(.top, 32)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: 210)
    }

    func compareCard(pathStore: PathStore) -> some View {
        return ZStack {
            Image("viewer_compare")
                .resizable()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("내 방 비교")
                    .font(.bold, 24)
                    .foregroundStyle(Color.deepNavy)
                Text("입주 전/후 방 상태를\n비교해보세요")
                    .font(.medium, 16)
                    .foregroundStyle(Color.dustyBlue)
                    .lineSpacing(6)
                
                Button {
                    // TODO: 내 방 비교 화면 연결
                } label: {
                    Circle()
                        .fill(Color.mutedBlue)
                        .frame(width: 39, height: 39)
                        .overlay {
                            Image(systemName: "chevron.right")
                                .font(.semibold, 18)
                                .foregroundStyle(Color.deepNavy)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 29)
            .padding(.top, 32)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: 210)
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
                    pathStore.defectPath.append(.defect(.defectList))
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
    let room: DefectRoomData
    let onTap: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    var body: some View {
        HStack(spacing: 16) {
            thumbnailView
            VStack(alignment: .leading, spacing: 16) {
                Text(room.title)
                    .font(.semibold, 16)
                    .foregroundStyle(Color.neutral800)
                Text(Self.dateFormatter.string(from: room.date))
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
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
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
        Color(.systemGray5)
            .overlay {
                Image(systemName: "house.fill")
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    NavigationStack {
        ViewerView()
    }
    .environment(\.di, DIContainer.configured())
}
