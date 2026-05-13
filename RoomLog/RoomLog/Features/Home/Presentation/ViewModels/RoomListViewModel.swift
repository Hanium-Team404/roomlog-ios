//
//  RoomListViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

@Observable
final class RoomListViewModel {

    // MARK: - Provider

    private let provider: HomeUseCaseProvider

    // MARK: - State

    private(set) var houseName: String
    private(set) var rooms: [RoomSummary] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    var isEditing: Bool = false
    var roomToDelete: RoomSummary?

    let houseId: Int

    // MARK: - Init

    init(houseId: Int, houseName: String, provider: HomeUseCaseProvider) {
        self.houseId = houseId
        self.houseName = houseName
        self.provider = provider
    }

    // MARK: - Actions

    @MainActor
    func fetchRooms() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await provider.makeGetHouseRoomsUseCase().execute(houseId: houseId)
            houseName = result.houseName
            rooms = result.rooms
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func deleteRoom(_ room: RoomSummary) async {
        do {
            try await provider.makeDeleteRoomUseCase().execute(roomId: room.id)
            rooms.removeAll { $0.id == room.id }
            await PLYFileCache.shared.removeCache(for: room.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
