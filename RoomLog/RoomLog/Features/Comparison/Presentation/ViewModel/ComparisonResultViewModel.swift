//
//  ComparisonResultViewModel.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

@Observable
final class ComparisonResultViewModel {
    // MARK: - Phase
    enum Phase: Equatable {
        case loading
        case polling
        case completed
        case failed(String)
    }

    // MARK: - PLY Toggle
    enum PLYMode: String, CaseIterable {
        case moveIn = "이전"
        case moveOut = "이후"
    }

    // MARK: - State
    private(set) var phase: Phase = .loading
    private(set) var result: AnalysisResult?
    private(set) var moveInPLYURL: URL?
    private(set) var moveOutPLYURL: URL?
    var plyMode: PLYMode = .moveOut
    var errorMessage: String?

    /// 현재 선택된 모드의 PLY URL
    var currentPLYURL: URL? {
        plyMode == .moveIn ? moveInPLYURL : moveOutPLYURL
    }

    /// 현재 모드에서 표시할 하자 오버레이 (입주 전이면 없음)
    var currentDefects: [DefectReportDetail] {
        plyMode == .moveIn ? [] : (result?.defects ?? [])
    }

    // MARK: - Context
    let moveInRoomId: Int
    let moveOutRoomId: Int
    private let provider: DefectUseCaseProvider

    init(moveInRoomId: Int, moveOutRoomId: Int, analysisID: Int? = nil, provider: DefectUseCaseProvider) {
        self.moveInRoomId = moveInRoomId
        self.moveOutRoomId = moveOutRoomId
        self.provider = provider
        // 내역에서 진입 시 analysisId를 바로 저장
        if let analysisID {
            saveAnalysisId(analysisID)
        }
    }

    // MARK: - Analysis ID Tracking
    private static let analysisIdPrefix = "comparisonAnalysisId_"

    private var storageKey: String {
        "\(Self.analysisIdPrefix)\(moveInRoomId)_\(moveOutRoomId)"
    }

    private func savedAnalysisId() -> Int? {
        let value = UserDefaults.standard.integer(forKey: storageKey)
        return value == 0 ? nil : value
    }

    private func saveAnalysisId(_ id: Int) {
        UserDefaults.standard.set(id, forKey: storageKey)
    }

    private func clearAnalysisId() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Main Flow

    func loadOrAnalyze() async {
        // 0. PLY 캐시 먼저 확인 (입주 전 / 퇴거 후 각각)
        if let cached = await PLYFileCache.shared.cachedFileURL(for: moveInRoomId) {
            moveInPLYURL = cached
        }
        if let cached = await PLYFileCache.shared.cachedFileURL(for: moveOutRoomId) {
            moveOutPLYURL = cached
        }

        // 1. 저장된 analysisId가 있으면 상태 확인
        if let savedId = savedAnalysisId() {
            do {
                let status = try await provider.makeGetAnalysisStatusUseCase().execute(analysisId: savedId).uppercased()
                switch status {
                case "COMPLETED":
                    // 완료된 결과 바로 표시 (analysisId 유지 — 재진입 시 다시 조회 가능)
                    await fetchResult(analysisId: savedId)
                    return
                case "FAILED":
                    clearAnalysisId()
                default:
                    // PENDING → polling 재개
                    await resumePolling(analysisId: savedId)
                    return
                }
            } catch let error as RepositoryError {
                if error.serverErrorCode == .analysisNotFound {
                    clearAnalysisId()
                } else {
                    phase = .failed(error.userMessage)
                    return
                }
            } catch {
                phase = .failed(error.localizedDescription)
                return
            }
        }

        // 2. 새 분석 요청
        await startAnalysis()
    }

    // MARK: - Analysis

    func startAnalysis() async {
        guard phase != .polling else { return }
        phase = .polling

        let analysisId: Int
        do {
            let result = try await provider.makeRequestAnalysisUseCase().execute(
                inRoomId: moveInRoomId,
                outRoomId: moveOutRoomId
            )
            analysisId = result.analysisId
            saveAnalysisId(analysisId)

            let status = result.status.uppercased()
            if status == "COMPLETED" {
                await fetchResult(analysisId: analysisId)
                return
            }
            if status == "FAILED" {
                clearAnalysisId()
                phase = .failed("서버에서 분석에 실패했습니다")
                return
            }
        } catch {
            phase = .failed("분석 요청 실패: \(error.localizedDescription)")
            return
        }

        await pollUntilDone(analysisId: analysisId)
    }

    private func resumePolling(analysisId: Int) async {
        guard phase != .polling else { return }
        phase = .polling
        await pollUntilDone(analysisId: analysisId)
    }

    // MARK: - Polling

    private enum PollConfig {
        static let intervalSeconds = 7
        static let maxConsecutiveErrors = 3
    }

    private func pollUntilDone(analysisId: Int) async {
        // ply_url을 먼저 받아서 3D 이미지 표시
        if result?.plyURL == nil {
            if let partialResult = try? await provider.makeGetAnalysisResultUseCase().execute(analysisId: analysisId),
               partialResult.plyURL != nil {
                result = partialResult
            }
        }

        var consecutiveErrors = 0
        while !Task.isCancelled {
            do {
                let status = try await provider.makeGetAnalysisStatusUseCase().execute(analysisId: analysisId).uppercased()
                consecutiveErrors = 0

                if status == "COMPLETED" {
                    break
                } else if status == "FAILED" {
                    clearAnalysisId()
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
        await fetchResult(analysisId: analysisId)
    }

    // MARK: - Fetch Result

    private func fetchResult(analysisId: Int) async {
        do {
            result = try await provider.makeGetAnalysisResultUseCase().execute(analysisId: analysisId)
            phase = .completed
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    // MARK: - PLY Download

    func downloadPLYIfNeeded() async {
        // 입주 전 PLY
        if moveInPLYURL == nil {
            await downloadPLY(for: moveInRoomId, assign: \.moveInPLYURL)
        }
        // 퇴거 후 PLY
        if moveOutPLYURL == nil {
            await downloadPLY(for: moveOutRoomId, assign: \.moveOutPLYURL)
        }
    }

    private func downloadPLY(for roomId: Int, assign keyPath: ReferenceWritableKeyPath<ComparisonResultViewModel, URL?>) async {
        if let cached = await PLYFileCache.shared.cachedFileURL(for: roomId) {
            self[keyPath: keyPath] = cached
            return
        }

        // 해당 방의 ply_url을 defects API에서 가져오기
        guard let report = try? await provider.makeGetDefectReportUseCase().execute(roomId: roomId),
              let urlString = report.imageURL,
              let remoteURL = URL(string: urlString) else { return }

        do {
            self[keyPath: keyPath] = try await PLYFileCache.shared.download(from: remoteURL, roomId: roomId)
        } catch {
            print("[Comparison] PLY download failed for room \(roomId): \(error)")
        }
    }
}
