//
//  HouseListViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

@Observable
final class HouseListViewModel {

    // MARK: - Provider

    private let provider: HomeUseCaseProvider

    // MARK: - State

    private(set) var houses: [House] = []
    private(set) var mainHouse: House?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    var isEditing: Bool = false {
        didSet { if isEditing { selectedHouseId = nil } }
    }
    var selectedHouseId: Int?
    var showSetMainSuccess: Bool = false
    var showDeleteConfirm: Bool = false
    var houseToEdit: House?

    // MARK: - Init

    init(provider: HomeUseCaseProvider) {
        self.provider = provider
    }

    // MARK: - Actions

    @MainActor
    func fetchHouses() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await provider.makeGetHousesUseCase().execute()
            houses = result.houses
            mainHouse = result.mainHouse
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func setMainHouse() async {
        guard let selectedId = selectedHouseId else { return }
        do {
            try await provider.makeSetMainHouseUseCase().execute(houseId: selectedId)
            mainHouse = houses.first { $0.houseId == selectedId }
            isEditing = false
            showSetMainSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func updateHouse(houseId: Int, name: String, address: String?) async throws {
        let updated = try await provider.makeUpdateHouseUseCase().execute(
            houseId: houseId, name: name, address: address
        )
        if let index = houses.firstIndex(where: { $0.houseId == houseId }) {
            houses[index] = updated
        }
        if mainHouse?.houseId == houseId {
            mainHouse = updated
        }
    }

    @MainActor
    func deleteSelectedHouse() async {
        guard let selectedId = selectedHouseId else { return }
        do {
            try await provider.makeDeleteHouseUseCase().execute(houseId: selectedId)
            houses.removeAll { $0.houseId == selectedId }
            selectedHouseId = nil
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
