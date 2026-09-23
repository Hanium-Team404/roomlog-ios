//
//  ScanProcessingManager.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation
import SwiftUI
import ZIPFoundation

@MainActor
@Observable
final class ScanProcessingManager {

    // MARK: - State

    private(set) var activeScan: ActiveScan?

    // MARK: - Dependencies

    private var scanRepository: ScanRepositoryProtocol?
    private let fileCache = PLYFileCache.shared
    private let pollConfig: PollConfig
    private let artifactStore: ScanArtifactStore
    private let gate = ScenePhaseGate()
    private var processingTask: Task<Void, Never>?

    // MARK: - Setup

    init(pollConfig: PollConfig = PollConfig(), artifactStore: ScanArtifactStore = ScanArtifactStore()) {
        self.pollConfig = pollConfig
        self.artifactStore = artifactStore
    }

    func configure(scanRepository: ScanRepositoryProtocol) {
        self.scanRepository = scanRepository
        artifactStore.sweepOrphans()
        resumeRestoredWork()
    }

    // MARK: - 조회 (UI가 읽는 것)

    /// 실패 후 사용 가능한 재시도 여부.
    /// 재시도 정보가 `.failed` 페이로드에 함께 있으므로 cross-house 오염은 구조적으로 불가능하다.
    var canRetry: Bool {
        guard case .failed(let failure) = activeScan?.phase else { return false }
        return failure.retrySource != nil
    }

    // MARK: - 시동

    /// 촬영 완료 후 호출. wrapUp → 압축 → 업로드 → 폴링 → 다운로드 전체 수행.
    func startFullProcess(encoder: DatasetEncoder, houseId: Int) {
        // 이전 스캔의 기록·zip이 남아 있으면 압축·업로드 중 앱 종료 시
        // 재시작 복구가 다른 집의 예전 스캔을 되살린다
        artifactStore.clear()
        start(.full(encoder: encoder), houseId: houseId)
    }

    /// 중단된 스캔의 폴링 재개 (앱 재시작 복구용)
    func resumePolling(scanId: Int, houseId: Int) {
        artifactStore.save(.polling(scanId: scanId, houseId: houseId))
        start(.polling(scanId: scanId), houseId: houseId)
    }

    /// 실패 지점에 맞는 진입점부터 재시도.
    /// 다시 실패하면 단계가 던진 실패를 디스패처가 `.failed(retrySource:)`로 재설정한다.
    func retry() {
        guard let activeScan,
              case .failed(let failure) = activeScan.phase,
              let source = failure.retrySource else { return }
        start(source.entry, houseId: activeScan.houseId)
    }

    // MARK: - 종료·신호

    /// 진행 중인 스캔 취소. 서버 스캔이 있으면 취소 요청 Task를 돌려준다 —
    /// 로그아웃처럼 요청 완료 후에 이어갈 작업(토큰 삭제)이 있으면 await해서 순서를 보장한다.
    @discardableResult
    func cancel() -> Task<Void, Never>? {
        let scanId = activeScan?.scanId ?? 0
        reset()

        // 저장소를 직접 캡처한다 — 로그아웃 시 매니저가 DI 캐시에서 해제돼도 요청이 나가야 한다
        guard scanId > 0, let scanRepository else { return nil }
        return Task {
            try? await scanRepository.cancelScan(scanId: scanId)
        }
    }

    /// 완료된 스캔 소비 (저장 완료 후 호출)
    func clear() {
        reset()
    }

    /// 앱 lifecycle 전환 시 호출
    func handleScenePhase(_ phase: ScenePhase) {
        gate.update(phase)
    }

    #if DEBUG
    func setActiveScan(_ scan: ActiveScan?) {
        activeScan = scan
    }

    /// 테스트에서 폴링 루프가 실제로 파킹됐는지 관측하기 위한 노출
    var isParked: Bool { gate.isParked }
    var currentTask: Task<Void, Never>? { processingTask }
    #endif

    // MARK: - Stage Lifecycle

    /// 진행 중인 Task를 취소하고 지정한 진입점부터 파이프라인을 실행한다.
    /// 시작·재시도·복원이 전부 이 디스패처를 통과하고,
    /// 단계가 던진 `ScanFailure`도 여기서만 `.failed`로 기록된다.
    /// 재시도 불가 실패의 기록·zip 폐기도 여기서만 한다 — 재시도 가능 여부와 재시작 복구 여부가 항상 일치한다.
    private func start(_ entry: PipelineEntry, houseId: Int) {
        cancelProcessingTask()
        activeScan = ActiveScan(scanId: entry.scanId, houseId: houseId, phase: entry.initialPhase)
        processingTask = Task { [weak self] in
            do {
                switch entry {
                case .full(let encoder):
                    try await self?.fullProcess(encoder: encoder, houseId: houseId)
                case .upload(let zipURL):
                    try await self?.uploadThenPoll(zipURL: zipURL, datasetDir: nil, houseId: houseId)
                case .polling(let scanId):
                    try await self?.pollAndDownload(scanId: scanId)
                case .download(let scanId):
                    try await self?.downloadPreview(scanId: scanId)
                }
            } catch let failure as ScanFailure {
                // 취소된 Task의 늦은 실패가 정리·교체된 상태를 되살리지 않도록 한다
                guard let self, !Task.isCancelled else { return }
                if failure.retrySource == nil {
                    self.artifactStore.clear()
                }
                // 단계 전환이 반영된 최신 scanId를 유지한다 (업로드 성공 후 폴링 실패 등)
                self.activeScan = ActiveScan(
                    scanId: self.activeScan?.scanId ?? entry.scanId,
                    houseId: houseId,
                    phase: .failed(failure)
                )
            } catch {
                // CancellationError — 취소·교체로 죽는 Task는 상태를 건드리지 않고 조용히 끝난다
            }
        }
    }

    /// 진행 중인 Task를 취소하고, 게이트에 파킹돼 있으면 깨워서 취소를 인지시킨다
    private func cancelProcessingTask() {
        processingTask?.cancel()
        gate.wake()
    }

    /// 취소·소비 공통 정리: Task 취소, 상태 제거, 기록·zip 폐기
    private func reset() {
        cancelProcessingTask()
        activeScan = nil
        artifactStore.clear()
    }

    /// 진행 중 단계 전환 — houseId는 유지하고 phase(필요 시 scanId)만 바꾼다.
    /// 상태가 이미 정리됐다면(reset 경합) 죽은 스캔을 되살리지 않도록 건너뛴다.
    private func advance(to phase: ProcessingPhase, scanId: Int? = nil) {
        guard let current = activeScan else { return }
        activeScan = ActiveScan(scanId: scanId ?? current.scanId, houseId: current.houseId, phase: phase)
    }

    // MARK: - Restore

    /// 앱 재시작 시 저장된 진행 단계 복원.
    /// 폴링 기록은 재폴링으로, 업로드 미완 기록은 재시도 가능한 실패 상태로 되살린다.
    private func resumeRestoredWork() {
        switch artifactStore.restore() {
        case .polling(let scanId, let houseId):
            resumePolling(scanId: scanId, houseId: houseId)
        case .uploadRetry(let zipURL, let houseId):
            // Task를 띄우지 않고 상태만 복원 — 기존 재시도 UI(ScanStatusSheet)가 그대로 작동한다
            activeScan = ActiveScan(
                scanId: 0, houseId: houseId,
                phase: .failed(ScanFailure(userMessage: "업로드가 완료되지 않았습니다", retrySource: .upload(zipURL: zipURL)))
            )
        case nil:
            break
        }
    }

    // MARK: - Pipeline (실행 순서: fullProcess → uploadThenPoll → pollAndDownload → downloadPreview)
    // 실패는 ScanFailure를 던져 디스패처가 기록하고, 취소는 CancellationError로 조용히 끝난다.

    private func fullProcess(encoder: DatasetEncoder, houseId: Int) async throws {
        guard scanRepository != nil else { return }

        // 1. WrapUp
        await encoder.wrapUp()
        try Task.checkCancellation()

        // 2. Zip — 대용량 데이터셋의 동기 압축이라 메인 스레드에서 수행하면 UI가 멈춘다.
        // 생성 위치는 영속 디렉토리 — tmp는 앱 종료 시 OS가 청소할 수 있어 재시작 복구가 불가능하다
        let datasetDir = encoder.datasetDirectoryURL
        let zipURL = artifactStore.zipDestinationURL()
        do {
            try await Task.detached(priority: .userInitiated) {
                try FileManager.default.zipItem(at: datasetDir, to: zipURL, shouldKeepParent: false)
            }.value
            try Task.checkCancellation()
        } catch {
            // 실패·취소 공통: 재시도 경로가 없으므로 파편과 대용량 데이터셋을 즉시 정리한다
            cleanup(zipURL: zipURL, datasetDir: datasetDir)
            if error is CancellationError { throw error }
            #if DEBUG
            print("[ScanProcessing] 압축 실패: \(error)")
            #endif
            throw ScanFailure(userMessage: "스캔 데이터 압축에 실패했습니다", retrySource: nil)
        }

        // zip 완성 — 여기서부터는 앱이 죽어도 업로드 재시도로 복구할 수 있다
        artifactStore.save(.uploadReady(zipFileName: zipURL.lastPathComponent, houseId: houseId))

        // 3. 업로드부터는 재시도 경로와 공유한다
        advance(to: .uploading)
        try await uploadThenPoll(zipURL: zipURL, datasetDir: datasetDir, houseId: houseId)
    }

    /// zip 업로드 후 폴링 단계로 이어간다. 최초 업로드(datasetDir 있음)와 재시도(nil) 공용 경로.
    private func uploadThenPoll(zipURL: URL, datasetDir: URL?, houseId: Int) async throws {
        guard let scanRepository else { return }
        let scanResult: ScanResult
        do {
            scanResult = try await scanRepository.uploadScan(houseId: houseId, fileURL: zipURL)
        } catch {
            if Task.isCancelled {
                // cancel()의 reset이 기록·zip을 정리하지만 datasetDir는 스토어 밖이라 여기서 지운다
                cleanup(zipURL: zipURL, datasetDir: datasetDir)
                throw CancellationError()
            }
            removeDataset(datasetDir)
            // 재시도 가능하면 zip과 uploadReady 기록이 이미 영속 상태라 보존을 위해 할 일이 없고,
            // 불가하면 디스패처가 기록·zip을 폐기한다
            throw ScanFailure(
                userMessage: "업로드 실패: \(error.userMessage)",
                retrySource: error.isRetryable ? .upload(zipURL: zipURL) : nil
            )
        }
        removeDataset(datasetDir)
        // 취소됐다면 기록을 전환하지 않는다 — cancel()의 reset이 이미 기록·zip을 폐기했다
        try Task.checkCancellation()

        // 업로드 성공 — 단계를 폴링으로 원자 전환하고, 고아가 된 zip은 청소
        let scanId = scanResult.scanId
        artifactStore.save(.polling(scanId: scanId, houseId: houseId))
        artifactStore.sweepOrphans()
        advance(to: .polling, scanId: scanId)
        try await pollAndDownload(scanId: scanId)
    }

    private func pollAndDownload(scanId: Int) async throws {
        guard let scanRepository else { return }

        // COMPLETED가 나올 때까지 폴링
        var attempts = 0
        var consecutiveErrors = 0
        while true {
            // 백그라운드면 문이 열릴 때까지 파킹, 포그라운드면 즉시 통과
            await gate.waitUntilOpen()
            try Task.checkCancellation()

            attempts += 1
            if attempts > pollConfig.maxAttempts {
                // 서버 스캔은 파괴하지 않는다 — cancelScan은 유저의 명시적 취소에서만.
                // pending을 유지해 재시도(재폴링)와 앱 재시작 복구가 가능하게 한다
                throw ScanFailure(userMessage: "처리 시간이 초과되었습니다", retrySource: .polling(scanId: scanId))
            }

            // 요청이 나가 있는 동안 생명주기 전환이 있었는지 판별하기 위해 기록
            let transitionMark = gate.transitionCount
            do {
                let status = try await scanRepository.getScanStatus(scanId: scanId).uppercased()
                // 취소 후 늦게 도착한 응답이 다운로드로 진행하지 않도록 한다
                try Task.checkCancellation()
                consecutiveErrors = 0
                #if DEBUG
                print("[ScanProcessing] scanId=\(scanId) status=\(status)")
                #endif
                if status == "COMPLETED" { break }
                if status == "FAILED" {
                    throw ScanFailure(userMessage: "서버에서 스캔 처리에 실패했습니다", retrySource: nil)
                }
            } catch let error as RepositoryError {
                try Task.checkCancellation()
                // 요청 도중 생명주기 전환이 있었다면 전환으로 끊긴 실패일 수 있으므로
                // 횟수에 세지 않고 즉시 재시도한다 (백그라운드면 루프 상단에서 파킹).
                // continue는 sleep을 건너뛰어 시간이 흐르지 않으므로 attempts도 되돌린다
                if transitionMark != gate.transitionCount {
                    attempts -= 1
                    continue
                }
                consecutiveErrors += 1
                #if DEBUG
                print("[ScanProcessing] scanId=\(scanId) 상태 조회 실패(\(consecutiveErrors)/\(pollConfig.maxConsecutiveErrors)): \(error)")
                #endif
                if consecutiveErrors >= pollConfig.maxConsecutiveErrors {
                    // 일시적 네트워크 문제일 수 있는 비확정 실패 — pending을 유지해
                    // 재시도(재폴링)와 앱 재시작 복구가 가능하게 한다
                    throw ScanFailure(
                        userMessage: "상태 조회 실패: \(error.userMessage)",
                        retrySource: error.isRetryable ? .polling(scanId: scanId) : nil
                    )
                }
            }
            try? await Task.sleep(for: pollConfig.interval)
        }

        try await downloadPreview(scanId: scanId)
    }

    /// 프리뷰 다운로드. 폴링에서 COMPLETED를 확인한 뒤에만 호출된다.
    /// 재시도 가능한 실패는 서버 처리가 이미 완료이므로 기록을 유지한다 —
    /// 앱 재시작 시 폴링 재개 → COMPLETED 즉시 확인 → 재다운로드로 자연 복구된다.
    private func downloadPreview(scanId: Int) async throws {
        guard let scanRepository else { return }
        do {
            let fileURLString = try await scanRepository.getScanPreview(scanId: scanId)
            try Task.checkCancellation()
            guard let remoteURL = URL(string: fileURLString) else {
                throw ScanFailure(userMessage: "잘못된 파일 URL", retrySource: nil)
            }
            let localURL = try await fileCache.download(from: remoteURL, roomId: scanId)
            // 취소 후 완료된 다운로드(캐시 히트 등)가 취소된 스캔을 .completed로 되살리지 않도록 한다
            try Task.checkCancellation()
            advance(to: .completed(fileURL: localURL))
        } catch let failure as ScanFailure {
            throw failure
        } catch {
            // 취소로 끊긴 요청을 실패로 기록하지 않는다
            try Task.checkCancellation()
            // fileCache.download는 typed throws 경계 밖(URLSession)이라 여기서 정규화한다
            let repositoryError = RepositoryError.normalize(error)
            throw ScanFailure(
                userMessage: "프리뷰 다운로드 실패: \(repositoryError.userMessage)",
                retrySource: repositoryError.isRetryable ? .download(scanId: scanId) : nil
            )
        }
    }

    // MARK: - File Cleanup

    /// 압축·업로드 도중 중단 시 진행 중이던 파일 정리 (기록된 자산은 스토어가 관리)
    private func cleanup(zipURL: URL, datasetDir: URL?) {
        try? FileManager.default.removeItem(at: zipURL)
        removeDataset(datasetDir)
    }

    /// 업로드가 끝나 더 필요 없어진 캡처 데이터셋 삭제
    private func removeDataset(_ datasetDir: URL?) {
        guard let datasetDir else { return }
        try? FileManager.default.removeItem(at: datasetDir)
    }
}
