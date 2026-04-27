//
//  DefectUseCaseProvider.swift
//  RoomLog
//
//  Created by 김도연 on 4/14/26.
//

import Foundation

protocol DefectUseCaseProvider {
    func makeGetDefectRoomDataUseCase() -> GetDefectRoomDataUseCaseProtocol
    func makeGetDefectReportUseCase() -> GetDefectReportUseCaseProtocol
    func makeGetDefectReportDetailUseCase() -> GetDefectReportDetailUseCaseProtocol
}

final class DefectUseCaseProviderImpl: DefectUseCaseProvider {
    // MARK: - Repository
    private let defectRepository: DefectRepositoryProtocol

    // MARK: - Init
    init(defectRepository: DefectRepositoryProtocol) {
        self.defectRepository = defectRepository
    }

    // MARK: - Defect UseCases
    func makeGetDefectRoomDataUseCase() -> GetDefectRoomDataUseCaseProtocol {
        GetDefectRoomDataUseCase(repository: defectRepository)
    }

    func makeGetDefectReportUseCase() -> GetDefectReportUseCaseProtocol {
        GetDefectReportUseCase(repository: defectRepository)
    }

    func makeGetDefectReportDetailUseCase() -> GetDefectReportDetailUseCaseProtocol {
        GetDefectReportDetailUseCase(repository: defectRepository)
    }
}
