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

    // MARK: - Public

    /// 촬영 완료 후 호출. wrapUp → 압축 → 업로드 → 폴링 → 다운로드 전체 수행.
    func startFullProcess(encoder: DatasetEncoder, houseId: Int) {
        // 이전 스캔의 기록·zip이 남아 있으면 압축·업로드 중 앱 종료 시
        // 재시작 복구가 다른 집의 예전 스캔을 되살린다
        artifactStore.clear()
        startStage(ActiveScan(scanId: 0, houseId: houseId, phase: .zipping)) { [weak self] in
            await self?.fullProcess(encoder: encoder, houseId: houseId)
        }
    }

    /// 중단된 스캔의 폴링 재개 (앱 재시작 복구용)
    func resumePolling(scanId: Int, houseId: Int) {
        artifactStore.save(.polling(scanId: scanId, houseId: houseId))
        startStage(ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)) { [weak self] in
            await self?.pollAndDownload(scanId: scanId, houseId: houseId)
        }
    }

    /// 진행 중인 스캔 취소
    func cancel() {
        let scanId = activeScan?.scanId ?? 0
        reset()

        if scanId > 0 {
            Task { [weak self] in
                try? await self?.scanRepository?.cancelScan(scanId: scanId)
            }
        }
    }

    /// 완료된 스캔 소비 (저장 완료 후 호출)
    func clear() {
        reset()
    }

    /// 실패 후 사용 가능한 재시도 여부.
    /// 재시도 정보가 `.failed` 페이로드에 함께 있으므로 cross-house 오염은 구조적으로 불가능하다.
    var canRetry: Bool {
        guard case .failed(let failure) = activeScan?.phase else { return false }
        return failure.retrySource != nil
    }

    /// 실패 지점에 맞는 방식으로 재시도.
    /// 업로드 실패는 보존된 zip 재업로드, 다운로드 실패는 동일 scanId 재다운로드.
    func retry() {
        guard let activeScan,
              case .failed(let failure) = activeScan.phase,
              let source = failure.retrySource else { return }
        let houseId = activeScan.houseId

        switch source {
        case .upload(let zipURL):
            startStage(ActiveScan(scanId: 0, houseId: houseId, phase: .uploading)) { [weak self] in
                await self?.uploadThenPoll(zipURL: zipURL, datasetDir: nil, houseId: houseId)
            }
        case .polling(let scanId):
            // 다시 실패하면 pollAndDownload가 .failed(retrySource:)를 재설정한다
            startStage(ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)) { [weak self] in
                await self?.pollAndDownload(scanId: scanId, houseId: houseId)
            }
        case .download(let scanId):
            // 다시 실패하면 downloadPreview가 .failed(retrySource:)를 재설정한다
            startStage(ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)) { [weak self] in
                await self?.downloadPreview(scanId: scanId, houseId: houseId)
            }
        }
    }

    /// 특정 houseId에 완료된 스캔이 있는지 확인
    func completedScan(for houseId: Int) -> ActiveScan? {
        guard let scan = activeScan,
              scan.houseId == houseId,
              case .completed = scan.phase else {
            return nil
        }
        return scan
    }

    /// 특정 houseId에 진행 중인 스캔이 있는지 확인
    func isProcessing(for houseId: Int) -> Bool {
        guard let scan = activeScan, scan.houseId == houseId else { return false }
        switch scan.phase {
        case .zipping, .uploading, .polling:
            return true
        default:
            return false
        }
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

    /// 진행 중인 Task를 취소하고 새 단계로 교체한다
    private func startStage(_ scan: ActiveScan, operation: @escaping () async -> Void) {
        cancelProcessingTask()
        activeScan = scan
        processingTask = Task { await operation() }
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

    // MARK: - Pipeline

    private func fullProcess(encoder: DatasetEncoder, houseId: Int) async {
        guard scanRepository != nil else { return }

        // 1. WrapUp
        await encoder.wrapUp()
        if Task.isCancelled { return }

        // 2. Zip — 대용량 데이터셋의 동기 압축이라 메인 스레드에서 수행하면 UI가 멈춘다.
        // 생성 위치는 영속 디렉토리 — tmp는 앱 종료 시 OS가 청소할 수 있어 재시작 복구가 불가능하다
        let datasetDir = encoder.datasetDirectoryURL
        let zipURL = artifactStore.zipDestinationURL()
        do {
            try await Task.detached(priority: .userInitiated) {
                try FileManager.default.zipItem(at: datasetDir, to: zipURL, shouldKeepParent: false)
            }.value
        } catch {
            // 압축 실패는 재시도 경로가 없으므로 대용량 데이터셋을 즉시 정리해 파일을 남기지 않는다
            cleanup(zipURL: zipURL, datasetDir: datasetDir)
            #if DEBUG
            print("[ScanProcessing] 압축 실패: \(error)")
            #endif
            activeScan = ActiveScan(
                scanId: 0, houseId: houseId,
                phase: .failed(ScanFailure(userMessage: "스캔 데이터 압축에 실패했습니다", retrySource: nil))
            )
            return
        }
        if Task.isCancelled { cleanup(zipURL: zipURL, datasetDir: datasetDir); return }

        // zip 완성 — 여기서부터는 앱이 죽어도 업로드 재시도로 복구할 수 있다
        artifactStore.save(.uploadReady(zipFileName: zipURL.lastPathComponent, houseId: houseId))

        // 3. 업로드부터는 재시도 경로와 공유한다
        activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .uploading)
        await uploadThenPoll(zipURL: zipURL, datasetDir: datasetDir, houseId: houseId)
    }

    /// zip 업로드 후 폴링 단계로 이어간다. 최초 업로드(datasetDir 있음)와 재시도(nil) 공용 경로.
    private func uploadThenPoll(zipURL: URL, datasetDir: URL?, houseId: Int) async {
        guard let scanRepository else { return }
        let scanResult: ScanResult
        do {
            scanResult = try await scanRepository.uploadScan(houseId: houseId, fileURL: zipURL)
        } catch {
            if Task.isCancelled {
                // cancel()의 reset이 기록·zip을 정리하지만 datasetDir는 스토어 밖이라 여기서 지운다
                cleanup(zipURL: zipURL, datasetDir: datasetDir)
                return
            }
            if let datasetDir {
                try? FileManager.default.removeItem(at: datasetDir)
            }
            let retrySource: RetrySource?
            if error.isRetryable {
                // zip과 uploadReady 기록은 이미 영속 상태 — 보존을 위해 할 일이 없다
                retrySource = .upload(zipURL: zipURL)
            } else {
                // 재시도해도 결과가 같은 실패면 zip·기록을 보존할 이유가 없다
                artifactStore.clear()
                retrySource = nil
            }
            activeScan = ActiveScan(
                scanId: 0, houseId: houseId,
                phase: .failed(ScanFailure(userMessage: "업로드 실패: \(error.userMessage)", retrySource: retrySource))
            )
            return
        }
        if let datasetDir {
            try? FileManager.default.removeItem(at: datasetDir)
        }
        // 취소됐다면 기록을 전환하지 않는다 — cancel()의 reset이 이미 기록·zip을 폐기했다
        if Task.isCancelled { return }

        // 업로드 성공 — 단계를 폴링으로 원자 전환하고, 고아가 된 zip은 청소
        let scanId = scanResult.scanId
        artifactStore.save(.polling(scanId: scanId, houseId: houseId))
        artifactStore.sweepOrphans()
        activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
        await pollAndDownload(scanId: scanId, houseId: houseId)
    }

    private func cleanup(zipURL: URL, datasetDir: URL?) {
        try? FileManager.default.removeItem(at: zipURL)
        if let datasetDir {
            try? FileManager.default.removeItem(at: datasetDir)
        }
    }

    // MARK: - Poll & Download

    private func pollAndDownload(scanId: Int, houseId: Int) async {
        guard let scanRepository else { return }

        // Poll until completed
        var attempts = 0
        var consecutiveErrors = 0
        while !Task.isCancelled {
            // 백그라운드면 문이 열릴 때까지 파킹, 포그라운드면 즉시 통과
            await gate.waitUntilOpen()
            if Task.isCancelled { return }

            attempts += 1
            if attempts > pollConfig.maxAttempts {
                // 서버 스캔은 파괴하지 않는다 — cancelScan은 유저의 명시적 취소에서만.
                // pending을 유지해 재시도(재폴링)와 앱 재시작 복구가 가능하게 한다
                activeScan = ActiveScan(
                    scanId: scanId, houseId: houseId,
                    phase: .failed(ScanFailure(userMessage: "처리 시간이 초과되었습니다", retrySource: .polling(scanId: scanId)))
                )
                return
            }

            // 요청이 나가 있는 동안 생명주기 전환이 있었는지 판별하기 위해 기록
            let transitionMark = gate.transitionCount
            do {
                let status = try await scanRepository.getScanStatus(scanId: scanId).uppercased()
                // 취소 후 늦게 도착한 응답이 상태를 되살리지 않도록 한다
                if Task.isCancelled { return }
                consecutiveErrors = 0
                #if DEBUG
                print("[ScanProcessing] scanId=\(scanId) status=\(status)")
                #endif
                if status == "COMPLETED" {
                    break
                } else if status == "FAILED" {
                    activeScan = ActiveScan(
                        scanId: scanId, houseId: houseId,
                        phase: .failed(ScanFailure(userMessage: "서버에서 스캔 처리에 실패했습니다", retrySource: nil))
                    )
                    artifactStore.clear()
                    return
                }
            } catch {
                if Task.isCancelled { return }
                // 요청 도중 생명주기 전환이 있었다면 전환으로 끊긴 실패일 수 있으므로
                // 횟수에 세지 않고 즉시 재시도한다 (백그라운드면 루프 상단에서 파킹)
                if transitionMark != gate.transitionCount {
                    // continue는 sleep을 건너뛰어 시간이 흐르지 않으므로 attempts도 되돌린다.
                    // 안 되돌리면 전환이 반복될 때 실제 대기 없이 maxAttempts를 소진해
                    // 타임아웃 취소(cancelScan + pending 삭제)로 스캔을 잃는다
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
                    let retrySource: RetrySource? = error.isRetryable ? .polling(scanId: scanId) : nil
                    activeScan = ActiveScan(
                        scanId: scanId, houseId: houseId,
                        phase: .failed(ScanFailure(userMessage: "상태 조회 실패: \(error.userMessage)", retrySource: retrySource))
                    )
                    return
                }
            }
            try? await Task.sleep(for: pollConfig.interval)
        }

        if Task.isCancelled { return }

        await downloadPreview(scanId: scanId, houseId: houseId)
    }

    /// 프리뷰 다운로드. 폴링에서 COMPLETED를 확인한 뒤에만 호출된다.
    /// 실패해도 서버 처리는 이미 완료이므로 pending을 지우지 않는다 —
    /// 앱 재시작 시 폴링 재개 → COMPLETED 즉시 확인 → 재다운로드로 자연 복구된다.
    private func downloadPreview(scanId: Int, houseId: Int) async {
        guard let scanRepository else { return }
        do {
            let fileURLString = try await scanRepository.getScanPreview(scanId: scanId)
            // 취소 후 도착한 응답이 잘못된 URL이면 guard-else가 .failed를 되살리므로
            // URL 검증 전에 취소를 확인한다 (불필요한 다운로드 시작도 방지)
            if Task.isCancelled { return }
            guard let remoteURL = URL(string: fileURLString) else {
                activeScan = ActiveScan(
                    scanId: scanId, houseId: houseId,
                    phase: .failed(ScanFailure(userMessage: "잘못된 파일 URL", retrySource: nil))
                )
                return
            }
            let localURL = try await fileCache.download(from: remoteURL, roomId: scanId)
            // 취소 후 완료된 다운로드(캐시 히트 등)가 취소된 스캔을 .completed로 되살리지 않도록 한다
            if Task.isCancelled { return }
            activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .completed(fileURL: localURL))
        } catch {
            if Task.isCancelled { return }
            // fileCache.download는 typed throws 경계 밖(URLSession)이라 여기서 정규화한다
            let repositoryError = RepositoryError.normalize(error)
            let retrySource: RetrySource? = repositoryError.isRetryable ? .download(scanId: scanId) : nil
            activeScan = ActiveScan(
                scanId: scanId, houseId: houseId,
                phase: .failed(ScanFailure(userMessage: "프리뷰 다운로드 실패: \(repositoryError.userMessage)", retrySource: retrySource))
            )
        }
    }
}
