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
    private(set) var items: [DefectRoomData] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependency
    private let useCase: GetDefectRoomDataUseCaseProtocol

    init(useCase: GetDefectRoomDataUseCaseProtocol) {
        self.useCase = useCase
    }

    // MARK: - Function
    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await useCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
