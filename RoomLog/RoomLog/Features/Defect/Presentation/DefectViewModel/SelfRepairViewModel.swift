//
//  SelfRepairViewModel.swift
//  RoomLog
//
//  Created by wk1717 on 8/26/26.
//

import Foundation

@Observable
final class SelfRepairViewModel {
    // MARK: - State
    private(set) var guide: SelfRepairGuide?
    private(set) var isLoading = false
    private(set) var loadFailed = false

    // MARK: - Dependency
    private let defectId: Int
    private let provider: DefectUseCaseProvider

    init(defectId: Int, provider: DefectUseCaseProvider) {
        self.defectId = defectId
        self.provider = provider
    }

    // MARK: - Function

    /// 자가 수리 안내 조회. 최초 호출 시 서버에서 GPT로 생성하므로 중복 호출을 막는다.
    func fetch() async {
        guard guide == nil, !isLoading else { return }
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            guide = try await provider.makeGetSelfRepairGuideUseCase().execute(defectId: defectId)
        } catch {
            loadFailed = true
        }
    }

    func retry() async {
        loadFailed = false
        await fetch()
    }
}
