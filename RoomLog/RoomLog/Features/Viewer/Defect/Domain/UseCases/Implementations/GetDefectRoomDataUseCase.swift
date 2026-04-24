//
//  GetDefectRoomDataUseCase.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation

final class GetDefectRoomDataUseCase: GetDefectRoomDataUseCaseProtocol {
    // MARK: - Property
    private let repository: DefectRepositoryProtocol

    // MARK: - Init
    init(repository: DefectRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function
    func execute() async throws -> DefectRoomData {
        try await repository.getDefectRoomData()
    }
}
