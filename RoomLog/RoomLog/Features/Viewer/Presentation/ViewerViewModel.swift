//
//  ViewerViewModel.swift
//  RoomLog
//
//  Created by 송민교 on 5/6/26.
//

import Foundation

@Observable
@MainActor
final class ViewerViewModel {
    private(set) var rooms: [RoomSummary] = []
    private(set) var houses: [House] = []
    private(set) var isLoading = false

    private let homeProvider: HomeUseCaseProvider
    private let homeState: HomeState

    init(homeProvider: HomeUseCaseProvider, homeState: HomeState) {
        self.homeProvider = homeProvider
        self.homeState = homeState
    }

    var selectedHouse: House? {
        get { homeState.selectedHouse }
        set { homeState.selectedHouse = newValue }
    }

    func fetchHouses() async {
        do {
            let houseList = try await homeProvider.makeGetHousesUseCase().execute()
            houses = houseList.houses
            if let currentId = selectedHouse?.id,
               let refreshed = houseList.houses.first(where: { $0.id == currentId }) {
                selectedHouse = refreshed
            } else {
                selectedHouse = houseList.mainHouse ?? houseList.houses.first
            }
        } catch {
            // TODO: 에러 처리
        }
    }

    func fetchRooms() async {
        guard let houseId = selectedHouse?.id else {
            rooms = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let houseRooms = try await homeProvider.makeGetHouseRoomsUseCase().execute(houseId: houseId)
            rooms = houseRooms.rooms
        } catch {
            // TODO: 에러 처리
        }
    }

    var selectedHouseDisplayName: String {
        guard let name = selectedHouse?.name else { return "집 선택" }
        if name.count > 4 {
            return String(name.prefix(4)) + "..."
        }
        return name
    }
}
