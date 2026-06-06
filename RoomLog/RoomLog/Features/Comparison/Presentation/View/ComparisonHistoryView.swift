//
//  ComparisonHistoryView.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import SwiftUI

struct ComparisonHistoryView: View {
    @Environment(\.di) var di
    @State private var viewModel: ComparisonHistoryViewModel

    init(provider: ComparisonUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: ComparisonHistoryViewModel(provider: provider)
        )
    }

    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        VStack(spacing: 0) {
            if !viewModel.houses.isEmpty {
                houseSelector
            }

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                Spacer()
                Text(errorMessage)
                    .font(.medium, 14)
                    .foregroundStyle(Color.blueGray500)
                Spacer()
            } else if viewModel.histories.isEmpty {
                Spacer()
                emptyView
                Spacer()
            } else {
                historyList(pathStore: pathStore)
            }
        }
        .safeAreaInset(edge: .bottom) {
            newComparisonButton(pathStore: pathStore)
        }
        .navigationTitle("내 방 비교")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchHouses()
        }
    }
}

// MARK: - House Selector
private extension ComparisonHistoryView {
    var houseSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.houses) { house in
                    Button {
                        viewModel.selectHouse(house)
                    } label: {
                        Text(house.name)
                            .font(.medium, 14)
                            .foregroundStyle(viewModel.selectedHouse?.id == house.id ? .white : Color.neutral800)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedHouse?.id == house.id ? Color.mutedBlue : Color.blueGray50,
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - History List
private extension ComparisonHistoryView {
    func historyList(pathStore: PathStore) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.histories) { history in
                    ComparisonHistoryCard(history: history)
                        .opacity(history.isCompleted ? 1 : 0.7)
                        .onTapGesture {
                            guard history.isCompleted else { return }
                            pathStore.defectPath.append(
                                .defect(.comparisonResult(
                                    moveInRoomId: history.moveInRoomId,
                                    moveOutRoomId: history.moveOutRoomId,
                                    analysisID: history.id
                                ))
                            )
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Empty View
private extension ComparisonHistoryView {
    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.and.right.square")
                .font(.system(size: 48))
                .foregroundStyle(Color.blueGray300)
            Text("비교 내역이 없습니다")
                .font(.medium, 16)
                .foregroundStyle(Color.blueGray500)
            Text("새 비교를 시작해보세요")
                .font(.regular, 14)
                .foregroundStyle(Color.blueGray300)
        }
    }
}

// MARK: - New Comparison Button
private extension ComparisonHistoryView {
    func newComparisonButton(pathStore: PathStore) -> some View {
        BottomCTAButton {
            pathStore.defectPath.append(.defect(.comparisonSelect))
        } label: {
            Text("새 비교하기")
                .font(.semibold, 17)
        }
    }
}

// MARK: - History Card
private struct ComparisonHistoryCard: View {
    let history: ComparisonHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단: 방 이름 + 상태 뱃지
            HStack(spacing: 10) {
                roomLabel(history.moveInRoomName, subtitle: "입주 전")
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.blueGray300)
                roomLabel(history.moveOutRoomName, subtitle: "퇴거 후")
                Spacer()
                StatusBadge(analysisStatus: history.status)
            }

            Divider()

            // 하단: 요약 정보
            HStack(spacing: 16) {
                if let date = history.createdAt {
                    InfoChip(icon: "calendar", text: date.toShortDisplayString())
                }
                if history.isCompleted {
                    InfoChip(icon: "exclamationmark.triangle", text: "하자 \(history.defectCount)건")
                    InfoChip(icon: "wonsign.circle", text: history.totalCost.formattedCost)
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
    }

    private func roomLabel(_ name: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(subtitle)
                .font(.regular, 12)
                .foregroundStyle(Color.blueGray400)
            Text(name)
                .font(.semibold, 16)
                .foregroundStyle(Color.neutral800)
        }
        .padding(.horizontal, 5)
    }
}


#Preview {
    NavigationStack {
        ComparisonHistoryView(
            provider: ComparisonUseCaseProviderImpl(
                repository: MockComparisonRepository()
            )
        )
    }
    .environment(\.di, DIContainer.configured())
}
