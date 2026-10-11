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

    func execute(defectId: Int) async throws -> DefectDetail {
        try await repository.getDefectDetail(defectId: defectId)
    }
}
