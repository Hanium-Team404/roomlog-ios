//
//  DefectDetailViewModel.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/11/26.
//

import Foundation

/// 하자 id로 상세 정보를 조회한다. 목록·챗봇·알림 등 모든 진입점이 id만 넘기므로 화면이 직접 데이터를 준비한다
@Observable
final class DefectDetailViewModel {
    // MARK: - State
    private(set) var detail: DefectDetail?
    private(set) var isLoading = false
    /// 조회 실패 시 사용자 노출 문구
    private(set) var errorMessage: String?

    // MARK: - Dependency
    private let defectId: Int
    private let provider: DefectUseCaseProvider

    init(defectId: Int, provider: DefectUseCaseProvider) {
        self.defectId = defectId
        self.provider = provider
    }

    // MARK: - Function

    func fetch() async {
        guard detail == nil, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            detail = try await provider.makeGetDefectReportDetailUseCase().execute(defectId: defectId)
        } catch {
            errorMessage = RepositoryError.normalize(error).userMessage
        }
    }

    func retry() async {
        errorMessage = nil
        await fetch()
    }
}
