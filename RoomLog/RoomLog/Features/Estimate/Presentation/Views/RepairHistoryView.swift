//
//  RepairHistoryView.swift
//  RoomLog
//
//  Created by minkyo on 5/17/26.
//

import SwiftUI

struct RepairHistoryView: View {
    @Environment(\.di) var di
    @State private var viewModel: RepairHistoryViewModel

    init(provider: EstimateUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: RepairHistoryViewModel(provider: provider)
        )
    }

    var body: some View {
        Group {
            if let report = viewModel.estimates.first {
                content
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                emptyView
            }
        }
        .navigationTitle("수리내역")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchEstimates()
        }
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.estimates) { estimate in
                    RepairHistoryCard(estimate: estimate)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Text("수리 내역이 없습니다")
                .font(.medium, 16)
                .foregroundStyle(Color.blueGray500)
        }
    }
}

// MARK: - Repair History Card

private struct RepairHistoryCard: View {
    let estimate: Estimate

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 20) {
                defectInfo
                dateAndShopInfo
            }
            Spacer()
            statusBadge
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
    }

    // MARK: - 하자 타입 + 심각도 + 위치

    private var defectInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(estimate.defectType)
                    .font(.semibold, 16)
                    .foregroundStyle(Color.neutral800)
                SeverityBadge(severity: estimate.defectSeverity)
            }
            Text(estimate.defectLocation)
                .font(.medium, 14)
                .foregroundStyle(Color.neutral400)
        }
    }

    // MARK: - 날짜 + 가격 + 업체
    private var dateAndShopInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.blueGray500)
                Text(formattedDate)
                    .font(.medium, 14)
                    .foregroundStyle(Color.blueGray600)
            }
            HStack(spacing: 16) {
                Text(formattedCost)
                    .font(.semibold, 14)
                    .foregroundStyle(Color.neutral700)
                Divider()
                    .frame(height: 16)
                Text(estimate.providerName)
                    .font(.medium, 14)
                    .foregroundStyle(Color.neutral700)
            }
        }
    }

    // MARK: - 상태 뱃지
    private var statusBadge: some View {
        Text(estimate.status.label)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(statusForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statusForeground: Color {
        switch estimate.status {
        case .sent, .requested:
            .white
        case .completed, .failed:
            Color.mutedBlue
        }
    }

    private var statusBackground: Color {
        switch estimate.status {
        case .sent, .requested:
            Color.mutedBlue
        case .completed, .failed:
            Color.blueGray50
        }
    }

    // MARK: - Formatting

    private var formattedDate: String {
        guard let date = estimate.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let s = formatter.string(from: NSNumber(value: estimate.repairCost)) ?? "\(estimate.repairCost)"
        return "₩ \(s)"
    }
}

// MARK: - Preview

#Preview {
    let di = DIContainer.configured()
    NavigationStack {
        RepairHistoryView(provider: di.resolve(EstimateUseCaseProvider.self))
    }
    .environment(\.di, di)
}
