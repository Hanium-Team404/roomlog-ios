//
//  RepairHistoryViewModel.swift
//  RoomLog
//
//  Created by minkyo on 5/17/26.
//

import Foundation

@Observable
final class RepairHistoryViewModel {
    // MARK: - State
    private(set) var estimates: [Estimate] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Provider
    private let provider: EstimateUseCaseProvider

    init(provider: EstimateUseCaseProvider) {
        self.provider = provider
    }

    // MARK: - Actions
    func fetchEstimates() async {
        isLoading = true
        defer { isLoading = false }
        do {
            estimates = try await provider.makeGetEstimatesUseCase().execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
