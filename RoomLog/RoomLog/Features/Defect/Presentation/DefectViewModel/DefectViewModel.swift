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
    private(set) var plyLocalURL: URL?
    var errorMessage: String?

    // MARK: - Provider
    let roomId: Int
    private let provider: DefectUseCaseProvider

    // MARK: - Local Analysis Tracking
    private static let analysisIdPrefix = "pendingAnalysisId_room_"

    private static func savedAnalysisId(for roomId: Int) -> Int? {
        let value = UserDefaults.standard.integer(forKey: "\(analysisIdPrefix)\(roomId)")
        return value == 0 ? nil : value
    }

    private static func saveAnalysisId(_ analysisId: Int, for roomId: Int) {
        UserDefaults.standard.set(analysisId, forKey: "\(analysisIdPrefix)\(roomId)")
    }

    private static func clearAnalysisId(for roomId: Int) {
        UserDefaults.standard.removeObject(forKey: "\(analysisIdPrefix)\(roomId)")
    }

    init(roomId: Int, provider: DefectUseCaseProvider) {
        self.roomId = roomId
        self.provider = provider
    }

    // MARK: - Function

    /// 1. PLY 캐시 확인
    /// 2. savedAnalysisId 있으면 상태 확인 → polling 재개 or 결과 표시
    /// 3. 없으면 POST /analyses → 서버가 COMPLETED면 결과 조회, PENDING이면 ply 먼저 받아서 표시 + polling
    func loadOrAnalyze() async {
        // 0. PLY 캐시 먼저 확인 (불필요한 다운로드 방지)
        if let cached = await PLYFileCache.shared.cachedFileURL(for: roomId) {
            plyLocalURL = cached
        }

        // 1. 저장된 analysisId가 있으면 상태 확인 (중복 분석 방지)
        if let savedId = Self.savedAnalysisId(for: roomId) {
            do {
                let status = try await provider.makeGetAnalysisStatusUseCase().execute(analysisId: savedId).uppercased()
                switch status {
                case "COMPLETED":
                    Self.clearAnalysisId(for: roomId)
                    await fetchReport()
                    return
                case "FAILED":
                    Self.clearAnalysisId(for: roomId)
                    // FAILED → 새 분석 시작
                default:
                    // PENDING → polling 재개
                    await resumePolling(analysisId: savedId)
                    return
                }
            } catch let error as RepositoryError {
                if error.serverErrorCode == .analysisNotFound {
                    Self.clearAnalysisId(for: roomId)
                } else {
                    phase = .failed(error.userMessage)
                    return
                }
            } catch {
                phase = .failed(error.localizedDescription)
                return
            }
        }

        // 2. 새 분석 요청 (or 서버가 기존 완료 분석 반환)
        await startAnalysis()
    }

    func fetchReport() async {
        do {
            report = try await provider.makeGetDefectReportUseCase().execute(roomId: roomId)
            phase = .completed
        } catch {
            errorMessage = error.localizedDescription
            phase = .failed(error.localizedDescription)
        }
    }

    private enum PollConfig {
        static let intervalSeconds = 7
        static let maxConsecutiveErrors = 3
    }

    /// 새 분석 요청 → polling → 완료 시 하자 데이터 로드
    func startAnalysis() async {
        guard phase != .polling else { return }
        phase = .polling
        preparePollingReport()

        // POST /analyses
        let analysisId: Int
        do {
            let result = try await provider.makeRequestAnalysisUseCase().execute(inRoomId: roomId, outRoomId: nil)
            analysisId = result.analysisId
            Self.saveAnalysisId(analysisId, for: roomId)

            let status = result.status.uppercased()
            if status == "COMPLETED" {
                Self.clearAnalysisId(for: roomId)
                await fetchReport()
                return
            }
            if status == "FAILED" {
                Self.clearAnalysisId(for: roomId)
                phase = .failed("서버에서 분석에 실패했습니다")
                return
            }
        } catch {
            phase = .failed("분석 요청 실패: \(error.localizedDescription)")
            return
        }

        await pollUntilDone(analysisId: analysisId)
    }

    /// 저장된 analysisId로 polling 재개
    private func resumePolling(analysisId: Int) async {
        guard phase != .polling else { return }
        phase = .polling
        preparePollingReport()
        await pollUntilDone(analysisId: analysisId)
    }

    /// polling 시작 전 report 준비 (기존 file_url 유지)
    private func preparePollingReport() {
        let existingImageURL = report?.imageURL
        let existingRoom = report?.room
        report = DefectReport(
            room: existingRoom ?? DefectRoomData(id: roomId, title: "", date: Date(), thumbnailURL: nil),
            imageURL: existingImageURL,
            defectCount: 0,
            minRepairCost: 0,
            repairArea: 0,
            defects: []
        )
    }

    /// 상태 polling → COMPLETED까지 대기
    private func pollUntilDone(analysisId: Int) async {
        // file_url이 없으면 한 번 조회 시도 (3D 이미지 먼저 표시)
        if report?.imageURL == nil {
            if let updatedReport = try? await provider.makeGetDefectReportUseCase().execute(roomId: roomId),
               updatedReport.imageURL != nil {
                report = DefectReport(
                    room: updatedReport.room,
                    imageURL: updatedReport.imageURL,
                    defectCount: 0,
                    minRepairCost: 0,
                    repairArea: 0,
                    defects: []
                )
            }
        }

        // 상태 polling (GET /analyses/{id}/status)
        var consecutiveErrors = 0
        while !Task.isCancelled {
            do {
                let status = try await provider.makeGetAnalysisStatusUseCase().execute(analysisId: analysisId).uppercased()
                consecutiveErrors = 0

                if status == "COMPLETED" {
                    Self.clearAnalysisId(for: roomId)
                    break
                } else if status == "FAILED" {
                    Self.clearAnalysisId(for: roomId)
                    phase = .failed("서버에서 분석에 실패했습니다")
                    return
                }
            } catch {
                if Task.isCancelled { return }
                consecutiveErrors += 1
                if consecutiveErrors >= PollConfig.maxConsecutiveErrors {
                    phase = .failed("상태 조회 실패: \(error.localizedDescription)")
                    return
                }
            }

            try? await Task.sleep(for: .seconds(PollConfig.intervalSeconds))
        }

        if Task.isCancelled { return }

        // 완료 → 하자 데이터 로드
        await fetchReport()
    }

    /// file_url이 있으면 PLY 파일 다운로드 → plyLocalURL에 저장
    func downloadPLYIfNeeded() async {
        guard plyLocalURL == nil,
              let urlString = report?.imageURL,
              let remoteURL = URL(string: urlString) else { return }

        // 캐시 확인
        if let cached = await PLYFileCache.shared.cachedFileURL(for: roomId) {
            plyLocalURL = cached
            return
        }

        do {
            plyLocalURL = try await PLYFileCache.shared.download(from: remoteURL, roomId: roomId)
        } catch {
            print("[Defect] PLY download failed: \(error)")
        }
    }

    #if DEBUG
    static func preview(phase: AnalysisPhase, report: DefectReport?, provider: DefectUseCaseProvider) -> DefectViewModel {
        let vm = DefectViewModel(roomId: 1, provider: provider)
        vm.phase = phase
        vm.report = report
        return vm
    }
    #endif
}
