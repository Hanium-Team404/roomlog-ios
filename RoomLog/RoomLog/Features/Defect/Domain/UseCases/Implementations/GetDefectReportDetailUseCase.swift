//
//  GetDefectReportDetailUseCase.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation

final class GetDefectReportDetailUseCase: GetDefectReportDetailUseCaseProtocol {
    private let repository: DefectRepositoryProtocol

    init(repository: DefectRepositoryProtocol) {
        self.repository = repository
    }

    func execute(roomId: Int) async throws -> DefectReportDetail {
        try await repository.getDefectReportDetail(roomId: roomId)
    }
}
