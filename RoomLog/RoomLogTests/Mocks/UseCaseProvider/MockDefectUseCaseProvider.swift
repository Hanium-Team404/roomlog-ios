//
//  MockDefectUseCaseProvider.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/11/26.
//

import Foundation
@testable import RoomLog

/// 하자 단건 조회만 결과를 주입하고, 나머지 유즈케이스는 `MockDefectRepository` 기반 기본 구현에 위임한다
final class MockDefectUseCaseProvider: DefectUseCaseProvider {

    // MARK: - Call Tracking

    var getDefectDetailCallCount = 0

    // MARK: - Stub Results

    var getDefectDetailResult: Result<DefectDetail, Error> = .success(
        DefectDetail(
            defect: DefectReportDetail(
                id: 1, analysisID: 1, imageURL: nil, type: .crack, severity: .high,
                description: "벽면 균열", repairCost: 80000, defectArea: 0.3, location: "거실 북쪽 벽",
                discoveredDate: nil, memo: nil, x: nil, y: nil, z: nil, region3d: []
            ),
            roomId: 5,
            roomImageURL: nil
        )
    )

    private let fallback: DefectUseCaseProviderImpl

    @MainActor
    init() {
        fallback = DefectUseCaseProviderImpl(defectRepository: MockDefectRepository())
    }

    // MARK: - DefectUseCaseProvider

    func makeGetDefectReportDetailUseCase() -> GetDefectReportDetailUseCaseProtocol {
        StubGetDefectDetailUseCase(result: getDefectDetailResult, onExecute: { self.getDefectDetailCallCount += 1 })
    }
    func makeGetDefectRoomDataUseCase() -> GetDefectRoomDataUseCaseProtocol {
        fallback.makeGetDefectRoomDataUseCase()
    }
    func makeGetDefectReportUseCase() -> GetDefectReportUseCaseProtocol {
        fallback.makeGetDefectReportUseCase()
    }
    func makeRequestAnalysisUseCase() -> RequestAnalysisUseCaseProtocol {
        fallback.makeRequestAnalysisUseCase()
    }
    func makeGetAnalysisStatusUseCase() -> GetAnalysisStatusUseCaseProtocol {
        fallback.makeGetAnalysisStatusUseCase()
    }
    func makeGetAnalysisResultUseCase() -> GetAnalysisResultUseCaseProtocol {
        fallback.makeGetAnalysisResultUseCase()
    }
    func makeGetSelfRepairGuideUseCase() -> GetSelfRepairGuideUseCaseProtocol {
        fallback.makeGetSelfRepairGuideUseCase()
    }
}

// MARK: - Stub UseCases

private struct StubGetDefectDetailUseCase: GetDefectReportDetailUseCaseProtocol {
    let result: Result<DefectDetail, Error>
    let onExecute: () -> Void
    func execute(defectId: Int) async throws -> DefectDetail {
        onExecute()
        return try result.get()
    }
}
