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
    private(set) var homeData: HomeData?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Init

    init(provider: HomeUseCaseProvider) {
        self.provider = provider
    }

    // MARK: - Actions

    @MainActor
    func fetchHouses() async {
        // TODO: House 목록 API 연동 시 UseCase 호출로 교체
        houses = [
            House(houseId: 1, name: "망고의 집", x: 750, y: 750),
            House(houseId: 2, name: "도도의 집", x: 350, y: 750)
        ]
    }
}
