//
//  GetDefectReportDetailUseCase.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation

final class GetDefectReportDetailUseCase: GetDefectReportDetailUseCaseProtocol {
    // MARK: - Property
    private let repository: DefectRepositoryProtocol

    // MARK: - Init
    init(repository: DefectRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function
    func execute(roomId: Int, reportId: Int) async throws -> DefectReportDetail {
        try await repository.getDefectReportDetail(roomId: roomId, reportId: reportId)
    }
}
