//
//  ComparisonViewModel.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

@Observable
final class ComparisonViewModel {
    private(set) var scans: [ComparisonScan] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var selectedMoveInScan: ComparisonScan?
    var selectedMoveOutScan: ComparisonScan?

    private let provider: ComparisonUseCaseProvider

    init(provider: ComparisonUseCaseProvider) {
        self.provider = provider
    }

    func fetchScans() async {
        isLoading = true
        defer { isLoading = false }
        do {
            scans = try await provider.makeGetComparisonScansUseCase().execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var moveInScans: [ComparisonScan] {
        scans.filter { $0.scanType == "IN" }
    }

    var moveOutScans: [ComparisonScan] {
        scans.filter { $0.scanType == "OUT" }
    }
}
