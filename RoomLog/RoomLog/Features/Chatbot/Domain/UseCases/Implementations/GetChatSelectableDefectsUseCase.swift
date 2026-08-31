//
//  GetChatSelectableDefectsUseCase.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

/// 하자 선택 sheet용 대표 집 하자 목록 조회 (C04, 최신순)
final class GetChatSelectableDefectsUseCase: GetChatSelectableDefectsUseCaseProtocol {
    private let repository: ChatRepositoryProtocol

    init(repository: ChatRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [ChatSelectableDefect] {
        try await repository.getMainHouseDefects()
    }
}
