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

    // MARK: - Dependency
    private let roomId: Int
    private let useCase: GetDefectReportUseCaseProtocol

    init(roomId: Int, useCase: GetDefectReportUseCaseProtocol) {
        self.roomId = roomId
        self.useCase = useCase
    }

    // MARK: - Function
    func fetchReport() async {
        isLoading = true
        defer { isLoading = false }
        do {
            report = try await useCase.execute(roomId: roomId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}
