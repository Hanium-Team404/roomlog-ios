//
//  UsecaseProvider.swift
//  Projects
//
//  Created by 김도연 on 3/31/26.
//

import Foundation

protocol UsecaseProvider {
    func makeGetDefectRoomDataUseCase() -> GetDefectRoomDataUseCaseProtocol
    func makeGetDefectReportUseCase() -> GetDefectReportUseCaseProtocol
    func makeGetDefectReportDetailUseCase() -> GetDefectReportDetailUseCaseProtocol
}

class UseCaseProvider: UsecaseProvider {
    // MARK: - Repository (같은 인스턴스를 각 UseCase에 공유)
    private let defectRepository: DefectRepositoryProtocol

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter) {
        self.defectRepository = DefectRepository(adapter: adapter)
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
