//
//  RepairHistoryViewModel.swift
//  RoomLog
//
//  Created by minkyo on 5/17/26.
//

import Foundation

@MainActor
@Observable
final class RepairHistoryViewModel {
    // MARK: - State
    private(set) var estimates: [Estimate] = []
    private(set) var isLoading = false
    private(set) var selectedDetail: EstimateDetail?
    private(set) var isLoadingDetail = false
    var errorMessage: String?
    var showSuccessToast = false

    // MARK: - Provider
    private let provider: EstimateUseCaseProvider
    private let roomId: Int

    init(roomId: Int, provider: EstimateUseCaseProvider) {
        self.roomId = roomId
        self.provider = provider
    }

    // MARK: - Actions
    func fetchEstimates() async {
        isLoading = true
        defer { isLoading = false }
        do {
            estimates = try await provider.makeGetEstimatesUseCase().execute(roomId: roomId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchEstimateDetail(estimateId: Int) async {
        isLoadingDetail = true
        defer { isLoadingDetail = false }
        do {
            selectedDetail = try await provider.makeGetEstimateDetailUseCase().execute(estimateId: estimateId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearDetail() {
        selectedDetail = nil
    }

    func completeRepair(estimateId: Int, repairCost: Int, note: String?) async {
        do {
            try await provider.makeCompleteRepairUseCase().execute(estimateId: estimateId, repairCost: repairCost, note: note)
            showSuccessToast = true
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        do {
            estimates = try await provider.makeGetEstimatesUseCase().execute(roomId: roomId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
