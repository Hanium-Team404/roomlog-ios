//
//  DefectViewModel.swift
//  RoomLog
//
//  Created by 송민교 on 4/22/26.
//

import Foundation

@Observable
final class DefectViewModel {
    // MARK: - Analysis Phase
    enum AnalysisPhase: Equatable {
        case loading
        case polling
        case completed
        case failed(String)
    }

    // MARK: - State
    private(set) var report: DefectReport?
    private(set) var phase: AnalysisPhase = .loading
    var errorMessage: String?

    // MARK: - Provider
    let roomId: Int
    private let provider: DefectUseCaseProvider
    private var pollingTask: Task<Void, Never>?

    init(roomId: Int, provider: DefectUseCaseProvider) {
        self.roomId = roomId
        self.provider = provider
    }

    // MARK: - Function
    func fetchReport() async {
        phase = .loading

        // 3D 이미지는 즉시 표시하기 위해 기본 정보 먼저 로드
        do {
            report = try await provider.makeGetDefectReportUseCase().execute(roomId: roomId)
            phase = .completed
        } catch {
            errorMessage = error.localizedDescription
            phase = .failed(error.localizedDescription)
        }
    }

    /// 목데이터용: polling 시뮬레이션 (API 연동 시 실제 polling으로 교체)
    func startAnalysis() async {
        phase = .polling

        // 3D 이미지용 기본 report 먼저 로드
        do {
            let baseReport = try await provider.makeGetDefectReportUseCase().execute(roomId: roomId)
            report = DefectReport(
                room: baseReport.room,
                imageURL: baseReport.imageURL,
                defectCount: 0,
                minRepairCost: 0,
                repairArea: 0,
                defects: []
            )
        } catch {
            phase = .failed(error.localizedDescription)
            return
        }

        // polling 시뮬레이션: 3초 후 완료
        try? await Task.sleep(for: .seconds(3))

        if Task.isCancelled { return }

        // 완료 후 전체 데이터 로드
        await fetchReport()
    }

    func cancelPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    #if DEBUG
    /// Preview 전용: 특정 phase로 고정된 ViewModel 생성
    static func preview(phase: AnalysisPhase, report: DefectReport?, provider: DefectUseCaseProvider) -> DefectViewModel {
        let vm = DefectViewModel(roomId: 1, provider: provider)
        vm.phase = phase
        vm.report = report
        return vm
    }
    #endif
}
