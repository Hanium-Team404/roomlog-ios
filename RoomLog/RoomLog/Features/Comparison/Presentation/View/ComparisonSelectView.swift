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
    @State private var scanType: ScanType = .moveIn

    init(provider: ComparisonUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: ComparisonViewModel(provider: provider)
        )
    }

    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        VStack(spacing: 0) {
            stepIndicator
                .padding(.vertical, 16)

            scanList

            Spacer()

            bottomButton(pathStore: pathStore)
        }
        .navigationTitle("비교할 방 선택")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchScans()
        }
    }
}

// MARK: - Step Indicator

private extension ComparisonSelectView {
    var stepIndicator: some View {
        HStack(spacing: 24) {
            stepLabel(number: 1, title: "입주 방 선택", isActive: scanType == .moveIn)
            stepLabel(number: 2, title: "퇴거 방 선택", isActive: scanType == .moveOut)
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
    var currentScans: [ComparisonScan] {
        scanType == .moveIn ? viewModel.moveInScans : viewModel.moveOutScans
    }

    var selectedScan: ComparisonScan? {
        scanType == .moveIn ? viewModel.selectedMoveInScan : viewModel.selectedMoveOutScan
    }

    var scanList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(currentScans) { scan in
                    ScanSelectionRow(
                        scan: scan,
                        isSelected: selectedScan?.id == scan.id
                    )
                    .onTapGesture {
                        if scanType == .moveIn {
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

// MARK: - Bottom Button

private extension ComparisonSelectView {
    @ViewBuilder
    func bottomButton(pathStore: PathStore) -> some View {
        let isEnabled = (scanType == .moveIn && viewModel.selectedMoveInScan != nil)
            || (scanType == .moveOut && viewModel.selectedMoveOutScan != nil)

        BottomCTAButton {
            if scanType == .moveIn {
                scanType = .moveOut
            } else if let moveIn = viewModel.selectedMoveInScan,
                      let moveOut = viewModel.selectedMoveOutScan {
                pathStore.defectPath.append(
                    .defect(.comparisonResult(moveInScanId: moveIn.id, moveOutScanId: moveOut.id))
                )
            }
        } label: {
            Text(scanType == .moveIn ? "다음" : "방 비교하기")
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
                Text(scan.scanDate.toShortDisplayString())
                    .font(.medium, 14)
                    .foregroundStyle(Color.blueGray300)
            }
            Spacer()
            if isSelected {
                Image("recommend_check")
                    .renderingMode(.template)
                    .frame(width:24, height: 24)
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
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 85)
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
        ComparisonSelectView(
            provider: ComparisonUseCaseProviderImpl(
                repository: MockComparisonRepository()
            )
        )
    }
    .environment(\.di, DIContainer.configured())
}
