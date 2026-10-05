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
    private(set) var errorMessage: String?

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

    /// 집 목록 조회가 실패하면 방 목록은 조회하지 않는다 — 방 조회 성공이 집 조회 에러를 지우지 않도록
    func refresh() async {
        await fetchHouses()
        guard errorMessage == nil else { return }
        await fetchRooms()
    }

    /// 다른 집으로 바꿀 때 조회가 실패해도 이전 집의 방 목록이 남지 않도록 먼저 비운다
    func selectHouse(_ house: House) async {
        selectedHouse = house
        rooms = []
        await fetchRooms()
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
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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
