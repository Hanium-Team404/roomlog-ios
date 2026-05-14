//
//  DefectViewModel.swift
//  RoomLog
//
//  Created by 송민교 on 4/22/26.
//

import Foundation

@Observable
final class DefectViewModel {
    // MARK: - State
    private(set) var report: DefectReport?
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Provider
    let roomId: Int
    private let provider: DefectUseCaseProvider

    init(roomId: Int, provider: DefectUseCaseProvider) {
        self.roomId = roomId
        self.provider = provider
    }

    // MARK: - Function
    func fetchReport() async {
        isLoading = true
        defer { isLoading = false }
        do {
            report = try await provider.makeGetDefectReportUseCase().execute(roomId: roomId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}
