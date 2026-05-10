//
//  ViewerViewModel.swift
//  RoomLog
//
//  Created by 송민교 on 5/6/26.
//

import Foundation

@Observable
final class ViewerViewModel {
    private(set) var rooms: [DefectRoomData] = []
    private(set) var isLoading = false

    private let useCase: GetDefectRoomDataUseCaseProtocol

    init(useCase: GetDefectRoomDataUseCaseProtocol) {
        self.useCase = useCase
    }

    func fetchRooms() async {
        isLoading = true
        defer { isLoading = false }
        do {
            rooms = try await useCase.execute()
        } catch {
            // TODO: 추후 추가 - @minkyo
        }
    }
}
