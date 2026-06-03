//
//  ComparisonSelectView.swift
//  RoomLog
//
//  Created by 송민교 on 5/21/26.
//

import SwiftUI
import NukeUI

struct ComparisonSelectView: View {
    @Environment(\.di) var di
    @State private var viewModel: ComparisonViewModel
    @State private var step: SelectionStep = .moveIn

    enum SelectionStep {
        case moveIn, moveOut
    }

    init(provider: ComparisonUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: ComparisonViewModel(provider: provider)
        )
    }

    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        VStack(spacing: 0) {
            // 집 선택
            if !viewModel.houses.isEmpty {
                houseSelector
            }

            stepIndicator
                .padding(.vertical, 16)

            scanList

            Spacer()

            bottomButton(pathStore: pathStore)
        }
        .navigationTitle("비교할 방 선택")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchHouses()
        }
    }
}

// MARK: - House Selector

private extension ComparisonSelectView {
    var houseSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.houses) { house in
                    Button {
                        viewModel.selectHouse(house)
                        step = .moveIn
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
            .padding(.top, 8)
        }
    }
}

// MARK: - Step Indicator

private extension ComparisonSelectView {
    var stepIndicator: some View {
        HStack(spacing: 24) {
            stepLabel(number: 1, title: "입주 전 방 선택", isActive: step == .moveIn)
            stepLabel(number: 2, title: "퇴거 후 방 선택", isActive: step == .moveOut)
        }
    }

    func stepLabel(number: Int, title: String, isActive: Bool) -> some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.semibold, 14)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(isActive ? Color.accentColor : Color.blueGray200, in: Circle())
            Text(title)
                .font(.medium, 14)
                .foregroundStyle(isActive ? Color.neutral800 : Color.blueGray200)
        }
    }
}

// MARK: - Scan List

private extension ComparisonSelectView {
    var selectedScan: ComparisonScan? {
        step == .moveIn ? viewModel.selectedMoveInScan : viewModel.selectedMoveOutScan
    }

    var scanList: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if viewModel.rooms.isEmpty {
                Text("방이 없습니다")
                    .font(.medium, 16)
                    .foregroundStyle(Color.blueGray300)
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.rooms) { scan in
                        ScanSelectionRow(
                            scan: scan,
                            isSelected: selectedScan?.id == scan.id
                        )
                        .onTapGesture {
                            if step == .moveIn {
                                viewModel.selectedMoveInScan = scan
                            } else {
                                viewModel.selectedMoveOutScan = scan
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Bottom Button

private extension ComparisonSelectView {
    @ViewBuilder
    func bottomButton(pathStore: PathStore) -> some View {
        let isEnabled = (step == .moveIn && viewModel.selectedMoveInScan != nil)
            || (step == .moveOut
                && viewModel.selectedMoveInScan != nil
                && viewModel.selectedMoveOutScan != nil)

        BottomCTAButton {
            if step == .moveIn {
                print("[Comparison] step: moveIn → moveOut, selected: \(viewModel.selectedMoveInScan?.roomName ?? "nil")")
                step = .moveOut
            } else if let moveIn = viewModel.selectedMoveInScan,
                      let moveOut = viewModel.selectedMoveOutScan {
                print("[Comparison] 방 비교하기 — moveIn: \(moveIn.id)(\(moveIn.roomName)), moveOut: \(moveOut.id)(\(moveOut.roomName))")
                pathStore.defectPath.append(
                    .defect(.comparisonResult(moveInRoomId: moveIn.id, moveOutRoomId: moveOut.id))
                )
            } else {
                print("[Comparison] 방 비교하기 실패 — moveIn: \(viewModel.selectedMoveInScan?.id as Any), moveOut: \(viewModel.selectedMoveOutScan?.id as Any)")
            }
        } label: {
            Text(step == .moveIn ? "다음" : "방 비교하기")
                .font(.semibold, 17)
        }
        .opacity(isEnabled ? 1 : 0.5)
        .allowsHitTesting(isEnabled)
    }
}

// MARK: - Scan Selection Row

struct ScanSelectionRow: View {
    let scan: ComparisonScan
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            thumbnailView
            VStack(alignment: .leading, spacing: 8) {
                Text(scan.roomName)
                    .font(.semibold, 16)
                    .foregroundStyle(Color.neutral800)
                if let date = scan.scanDate {
                    Text(date.toShortDisplayString())
                        .font(.medium, 14)
                        .foregroundStyle(Color.blueGray300)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.mutedBlue.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.mutedBlue.opacity(0.8) : Color.blueGray200, lineWidth: isSelected ? 1.2 : 1)
        )
        .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 8, x: 0, y: 2)
    }

    private var thumbnailView: some View {
        Group {
            if let urlString = scan.thumbnailURL, let url = URL(string: urlString) {
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
        .aspectRatio(1, contentMode: .fit)
        .containerRelativeFrame(.horizontal) { width, _ in width * 0.18 }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        ComparisonSelectView(
            provider: ComparisonUseCaseProviderImpl(
                repository: MockComparisonRepository()
            )
        )
    }
    .environment(\.di, DIContainer.configured())
}
