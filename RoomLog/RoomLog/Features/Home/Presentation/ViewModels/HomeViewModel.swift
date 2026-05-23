//
//  HomeViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 5/6/26.
//

import Foundation

@Observable
final class HomeViewModel {

    // MARK: - Provider

    private let provider: HomeUseCaseProvider

    // MARK: - State

    private(set) var houses: [House] = []
    private(set) var mainHouse: House?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    var showCreateSheet: Bool = false

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
    func createHouse(name: String, address: String?) async throws {
        let house = try await provider.makeCreateHouseUseCase().execute(name: name, address: address)
        houses.append(house)
    }
}
