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
    func makeRequestAnalysisUseCase() -> RequestAnalysisUseCaseProtocol
    func makeGetAnalysisStatusUseCase() -> GetAnalysisStatusUseCaseProtocol
    func makeGetAnalysisResultUseCase() -> GetAnalysisResultUseCaseProtocol
    func makeGetSelfRepairGuideUseCase() -> GetSelfRepairGuideUseCaseProtocol
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

    func makeRequestAnalysisUseCase() -> RequestAnalysisUseCaseProtocol {
        RequestAnalysisUseCase(repository: defectRepository)
    }

    func makeGetAnalysisStatusUseCase() -> GetAnalysisStatusUseCaseProtocol {
        GetAnalysisStatusUseCase(repository: defectRepository)
    }

    func makeGetAnalysisResultUseCase() -> GetAnalysisResultUseCaseProtocol {
        GetAnalysisResultUseCase(repository: defectRepository)
    }

    func makeGetSelfRepairGuideUseCase() -> GetSelfRepairGuideUseCaseProtocol {
        GetSelfRepairGuideUseCase(repository: defectRepository)
    }
}
