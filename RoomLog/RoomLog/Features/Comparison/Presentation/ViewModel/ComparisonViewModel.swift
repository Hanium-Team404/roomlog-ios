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
    var selectedMoveInScan: ComparisonScan? {
        didSet {
            guard let selected = selectedMoveOutScan else { return }
            if !moveOutCandidates.contains(where: { $0.id == selected.id }) {
                selectedMoveOutScan = nil
            }
        }
    }
    var selectedMoveOutScan: ComparisonScan?

    /// 이후 선택 목록: 이전 방의 스캔 날짜보다 늦게 스캔된 방만.
    /// 날짜가 없는 방은 순서를 판단할 수 없으므로 항상 표시하고, 이전으로 선택한 방 자신은 제외한다.
    var moveOutCandidates: [ComparisonScan] {
        guard let moveIn = selectedMoveInScan else { return rooms }
        return rooms.filter { scan in
            guard scan.id != moveIn.id else { return false }
            guard let baseDate = moveIn.scanDate, let date = scan.scanDate else { return true }
            return date > baseDate
        }
    }

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
