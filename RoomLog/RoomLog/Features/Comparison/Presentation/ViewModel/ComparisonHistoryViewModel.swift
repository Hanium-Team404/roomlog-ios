//
//  ComparisonHistoryViewModel.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

@MainActor
@Observable
final class ComparisonHistoryViewModel {
    private(set) var houses: [House] = []
    private(set) var histories: [ComparisonHistory] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var selectedHouse: House?

    private let provider: ComparisonUseCaseProvider
    private var fetchHistoriesTask: Task<Void, Never>?

    init(provider: ComparisonUseCaseProvider) {
        self.provider = provider
    }

    func fetchHouses() async {
        isLoading = true
        defer { isLoading = false }
        do {
            houses = try await provider.makeGetComparisonHousesUseCase().execute()
            if let selected = selectedHouse,
               houses.contains(where: { $0.id == selected.id }) {
                selectedHouse = selected
            } else {
                selectedHouse = houses.first
            }
            if let houseId = selectedHouse?.id {
                await fetchHistories(houseId: houseId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectHouse(_ house: House) {
        selectedHouse = house
        fetchHistoriesTask?.cancel()
        fetchHistoriesTask = Task { await fetchHistories(houseId: house.id) }
    }

    private func fetchHistories(houseId: Int) async {
        do {
            let fetched = try await provider.makeGetComparisonHistoriesUseCase().execute(houseId: houseId)
            guard !Task.isCancelled, selectedHouse?.id == houseId else { return }
            histories = fetched
        } catch {
            guard !Task.isCancelled else { return }
            histories = []
            errorMessage = error.localizedDescription
        }
    }
}
