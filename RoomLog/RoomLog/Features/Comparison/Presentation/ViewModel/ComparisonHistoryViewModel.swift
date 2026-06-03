//
//  ComparisonHistoryViewModel.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

@Observable
final class ComparisonHistoryViewModel {
    private(set) var houses: [House] = []
    private(set) var histories: [ComparisonHistory] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var selectedHouse: House?

    private let provider: ComparisonUseCaseProvider

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
            loadMockHistories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectHouse(_ house: House) {
        selectedHouse = house
        loadMockHistories()
    }

    // TODO: 서버 API 연동 시 교체
    private func loadMockHistories() {
        guard let house = selectedHouse else {
            histories = []
            return
        }
        // Mock 데이터 — 추후 GET /analyses?houseId= 로 교체
        histories = [
            ComparisonHistory(
                id: 101,
                moveInRoomName: "거실",
                moveOutRoomName: "거실",
                defectCount: 3,
                totalCost: 150000,
                createdAt: Date(timeIntervalSinceNow: -86400 * 2),
                moveInRoomId: 1,
                moveOutRoomId: 4
            ),
            ComparisonHistory(
                id: 102,
                moveInRoomName: "안방",
                moveOutRoomName: "안방",
                defectCount: 1,
                totalCost: 50000,
                createdAt: Date(timeIntervalSinceNow: -86400 * 7),
                moveInRoomId: 2,
                moveOutRoomId: 5
            )
        ]
    }
}
