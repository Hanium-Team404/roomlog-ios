//
//  ComparisonViewModel.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

@Observable
final class ComparisonViewModel {
    private(set) var houses: [House] = []
    private(set) var rooms: [ComparisonScan] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var selectedHouse: House?
    var selectedMoveInScan: ComparisonScan?
    var selectedMoveOutScan: ComparisonScan?

    private let provider: ComparisonUseCaseProvider
    private var fetchRoomsTask: Task<Void, Never>?

    init(provider: ComparisonUseCaseProvider) {
        self.provider = provider
    }

    func fetchHouses() async {
        isLoading = true
        defer { isLoading = false }
        do {
            houses = try await provider.makeGetComparisonHousesUseCase().execute()
            if selectedHouse == nil {
                selectedHouse = houses.first
            }
            if let houseId = selectedHouse?.id {
                await fetchRooms(houseId: houseId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchRooms(houseId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await provider.makeGetComparisonRoomsUseCase().execute(houseId: houseId)
            guard selectedHouse?.id == houseId else { return }
            rooms = result
        } catch {
            guard selectedHouse?.id == houseId else { return }
            rooms = []
            errorMessage = error.localizedDescription
        }
    }

    func selectHouse(_ house: House) {
        selectedHouse = house
        selectedMoveInScan = nil
        selectedMoveOutScan = nil
        fetchRoomsTask?.cancel()
        fetchRoomsTask = Task { await fetchRooms(houseId: house.id) }
    }
}
