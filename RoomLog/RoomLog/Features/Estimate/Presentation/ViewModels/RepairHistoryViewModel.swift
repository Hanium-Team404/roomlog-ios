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

    func completeRepair(estimateId: Int, repairCost: Int, note: String?) async {
        do {
            try await provider.makeCompleteRepairUseCase().execute(estimateId: estimateId, repairCost: repairCost, note: note)
            estimates = try await provider.makeGetEstimatesUseCase().execute(roomId: roomId)
            showSuccessToast = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
