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
    private(set) var rooms: [DefectRoomData] = []
    private(set) var houses: [House] = []
    private(set) var isLoading = false
    var selectedHouse: House?

    private let defectProvider: DefectUseCaseProvider
    private let homeProvider: HomeUseCaseProvider

    init(defectProvider: DefectUseCaseProvider, homeProvider: HomeUseCaseProvider) {
        self.defectProvider = defectProvider
        self.homeProvider = homeProvider
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
        isLoading = true
        defer { isLoading = false }
        do {
            rooms = try await defectProvider.makeGetDefectRoomDataUseCase().execute()
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
