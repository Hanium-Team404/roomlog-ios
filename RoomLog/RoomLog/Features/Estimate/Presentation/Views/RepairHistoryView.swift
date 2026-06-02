//
//  RepairHistoryView.swift
//  RoomLog
//
//  Created by 송민교 on 5/17/26.
//

import SwiftUI

struct RepairHistoryView: View {
    @Environment(\.di) var di
    @State private var viewModel: RepairHistoryViewModel
    @State private var selectedEstimate: Estimate?
    @State private var showDetail = false

    init(roomId: Int, provider: EstimateUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: RepairHistoryViewModel(roomId: roomId, provider: provider)
        )
    }

    var body: some View {
        Group {
            if viewModel.estimates.isEmpty && !viewModel.isLoading {
                emptyView
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                content
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
        .sheet(isPresented: $showDetail) {
            viewModel.clearDetail()
            selectedEstimate = nil
        } content: {
            if let estimate = selectedEstimate {
                EstimateDetailSheet(
                    estimate: estimate,
                    detail: viewModel.selectedDetail,
                    isLoadingDetail: viewModel.isLoadingDetail
                ) { repairCost, note in
                    await viewModel.completeRepair(estimateId: estimate.id, repairCost: repairCost, note: note)
                    showDetail = false
                }
            }
        }
        .overlay(alignment: .top) {
            if viewModel.showSuccessToast {
                SystemToastView(systemImage: "checkmark.circle.fill") {
                    Text("수리 완료가 등록되었습니다.")
                        .font(.medium, 14)
                        .foregroundStyle(Color.neutral600)
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { viewModel.showSuccessToast = false }
                }
            }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.estimates) { estimate in
                    RepairHistoryCard(estimate: estimate)
                        .onTapGesture {
                            selectedEstimate = estimate
                            showDetail = true
                            Task { await viewModel.fetchEstimateDetail(estimateId: estimate.id) }
                        }
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

// MARK: - Estimate Detail Sheet

private struct EstimateDetailSheet: View {
    let estimate: Estimate
    let detail: EstimateDetail?
    let isLoadingDetail: Bool
    let onComplete: (Int, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var repairCostText = ""
    @State private var note = ""
    @State private var isCompleting = false
    @State private var showPriceError = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd HH:mm"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 문의 날짜
            if let createdAt = detail?.createdAt ?? estimate.createdAt {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.blueGray500)
                    Text(Self.dateFormatter.string(from: createdAt))
                        .font(.medium, 14)
                        .foregroundStyle(Color.blueGray500)
                }
            }

            Text("문의 내용")
                .font(.semibold, 18)
                .foregroundStyle(Color.neutral800)

            if isLoadingDetail {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: 100)
            } else {
                ScrollView {
                    Text(detail?.message ?? estimate.message ?? "문자 전송 내역이 없습니다.")
                        .font(.regular, 15)
                        .foregroundStyle(Color.neutral600)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: 160)
                .background(Color.blueGray50, in: RoundedRectangle(cornerRadius: 12))
            }

            // 업체 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(detail?.providerName ?? estimate.providerName)
                    .font(.semibold, 16)
                    .foregroundStyle(Color.neutral800)
                if let phone = detail?.providerPhone ?? estimate.providerPhone, !phone.isEmpty {
                    Text(phone)
                        .font(.regular, 14)
                        .foregroundStyle(Color.blueGray500)
                }
                if let address = detail?.providerAddress ?? estimate.providerAddress, !address.isEmpty {
                    Text(address)
                        .font(.regular, 14)
                        .foregroundStyle(Color.blueGray500)
                }
            }

            if estimate.displayStatus == .inProgress {
                VStack(alignment: .leading, spacing: 12) {
                    Text("수리 비용 (원)")
                        .font(.medium, 14)
                        .foregroundStyle(Color.neutral600)
                    TextField("수리 비용을 입력하세요", text: $repairCostText)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(Color.blueGray50, in: RoundedRectangle(cornerRadius: 10))
                    if showPriceError {
                        Text("수리 비용을 입력해주세요.")
                            .font(.regular, 13)
                            .foregroundStyle(Color.red)
                    }

                    Text("메모")
                        .font(.medium, 14)
                        .foregroundStyle(Color.neutral600)
                    TextField("메모를 입력하세요 (선택)", text: $note)
                        .padding(12)
                        .background(Color.blueGray50, in: RoundedRectangle(cornerRadius: 10))
                }
            }

            Spacer()

            if estimate.displayStatus == .inProgress {
                Button {
                    guard let cost = Int(repairCostText), cost > 0 else {
                        showPriceError = true
                        return
                    }
                    showPriceError = false
                    isCompleting = true
                    Task {
                        await onComplete(cost, note.isEmpty ? nil : note)
                        isCompleting = false
                        dismiss()
                    }
                } label: {
                    Group {
                        if isCompleting {
                            ProgressView().tint(.white)
                        } else {
                            Text("수리 완료")
                                .font(.semibold, 17)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.mutedBlue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(isCompleting)
            }
        }
        .padding(24)
        .presentationDetents([.medium, .large])
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
            ForEach(estimate.defects) { defect in
                HStack(spacing: 10) {
                    Text(defect.localizedType)
                        .font(.semibold, 16)
                        .foregroundStyle(Color.neutral800)
                    SeverityBadge(severity: defect.severity)
                }
                Text(defect.location)
                    .font(.medium, 14)
                    .foregroundStyle(Color.neutral400)
            }
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
                if let cost = estimate.repairCost {
                    Text(formattedCost(cost))
                        .font(.semibold, 14)
                        .foregroundStyle(Color.neutral700)
                    Divider()
                        .frame(height: 16)
                } else if let estimatedCost = estimate.defects.first?.estimatedCost {
                    Text("예상 " + formattedCost(estimatedCost))
                        .font(.semibold, 14)
                        .foregroundStyle(Color.neutral500)
                    Divider()
                        .frame(height: 16)
                }
                Text(estimate.providerName)
                    .font(.medium, 14)
                    .foregroundStyle(Color.neutral700)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - 상태 뱃지

    private var statusBadge: some View {
        Text(estimate.displayStatus.label)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(statusForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statusForeground: Color {
        switch estimate.displayStatus {
        case .inProgress: .white
        case .completed: Color.mutedBlue
        }
    }

    private var statusBackground: Color {
        switch estimate.displayStatus {
        case .inProgress: Color.mutedBlue
        case .completed: Color.blueGray50
        }
    }

    // MARK: - Formatting

    private var formattedDate: String {
        estimate.createdAt?.toShortDisplayString() ?? ""
    }

    private func formattedCost(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let s = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩ \(s)"
    }
}

// MARK: - Preview

#Preview {
    let di = DIContainer.configured()
    NavigationStack {
        RepairHistoryView(roomId: 1, provider: di.resolve(EstimateUseCaseProvider.self))
    }
    .environment(\.di, di)
}
