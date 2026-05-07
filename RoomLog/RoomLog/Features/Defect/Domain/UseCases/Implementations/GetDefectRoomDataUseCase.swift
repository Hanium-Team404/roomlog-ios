//
//  GetDefectRoomDataUseCase.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation

final class GetDefectRoomDataUseCase: GetDefectRoomDataUseCaseProtocol {
    private let repository: DefectRepositoryProtocol

    init(repository: DefectRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [DefectRoomData] {
        try await repository.getDefectRoomData()
    }
}
