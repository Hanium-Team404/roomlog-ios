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
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

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
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
