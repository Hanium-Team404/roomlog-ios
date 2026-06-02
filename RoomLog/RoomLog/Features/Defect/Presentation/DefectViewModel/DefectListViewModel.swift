//
//  DefectListViewModel.swift
//  RoomLog
//
//  Created by 송민교 on 4/22/26.
//

import Foundation

@Observable
final class DefectListViewModel {
    // MARK: - State
    private(set) var items: [RoomSummary] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependency
    let houseId: Int
    private let homeProvider: HomeUseCaseProvider

    init(houseId: Int, homeProvider: HomeUseCaseProvider) {
        self.houseId = houseId
        self.homeProvider = homeProvider
    }

    // MARK: - Function
    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let houseRooms = try await homeProvider.makeGetHouseRoomsUseCase().execute(houseId: houseId)
            items = houseRooms.rooms
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
