//
//  ScanProcessingManager.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation
import SwiftUI
import ZIPFoundation

@Observable
final class ScanProcessingManager {

    // MARK: - Types

    enum ProcessingPhase: Equatable {
        case zipping
        case uploading
        case polling
        case completed(fileURL: URL)
        case failed(String)
    }

    struct ActiveScan: Equatable {
        let scanId: Int
        let houseId: Int
        let phase: ProcessingPhase
    }

    /// 폴링 간격·시도 횟수 설정. 테스트에서 짧은 간격을 주입할 수 있다.
    struct PollConfig {
        var maxAttempts = 60
        var interval: Duration = .seconds(7)
        var maxConsecutiveErrors = 3
    }

    /// 실패 지점에 따른 재시도 방식.
    enum RetrySource: Equatable {
        /// 업로드 실패: 보존해둔 zip으로 재업로드
        case upload(zipURL: URL)
        /// 상태 조회 실패: 서버 상태를 모르므로 재폴링부터 다시 수행
        case polling(scanId: Int)
        /// 프리뷰 다운로드 실패: 서버 처리는 이미 COMPLETED이므로 폴링 없이 재다운로드만 수행
        case download(scanId: Int)
    }

    /// 실패 후 재시도용 정보를 소유 houseId와 함께 보관.
    /// 다른 집의 새 스캔이 시작돼도 cross-house 재시도가 일어나지 않도록 한 단위로 묶는다.
    private struct PendingRetry {
        let houseId: Int
        let source: RetrySource
    }

    // MARK: - Persistence Keys

    private enum Defaults {
        static let scanIdKey = "ScanProcessing_scanId"
        static let houseIdKey = "ScanProcessing_houseId"
    }

    // MARK: - State

    private(set) var activeScan: ActiveScan?
    /// 실패 후 재시도용 정보. nil이면 재시도 불가.
    private var pendingRetry: PendingRetry?

    // MARK: - Dependencies

    private var scanRepository: ScanRepositoryProtocol?
    private let fileCache = PLYFileCache.shared
    private let pollConfig: PollConfig
    private let userDefaults: UserDefaults
    private var processingTask: Task<Void, Never>?
    private var isInBackground = false
    /// 백그라운드 동안 잠든 폴링 루프를 포그라운드 복귀 시 즉시 깨우기 위한 continuation
    private var foregroundWaiter: CheckedContinuation<Void, Never>?

    // MARK: - Setup

    init(pollConfig: PollConfig = PollConfig(), userDefaults: UserDefaults = .standard) {
        self.pollConfig = pollConfig
        self.userDefaults = userDefaults
    }

    func configure(scanRepository: ScanRepositoryProtocol) {
        self.scanRepository = scanRepository
        resumeIfNeeded()
    }

    // MARK: - Public

    /// 촬영 완료 후 호출. wrapUp → 압축 → 업로드 → 폴링 → 다운로드 전체 수행.
    func startFullProcess(encoder: DatasetEncoder, houseId: Int) {
        cancelProcessingTask()
        discardPendingRetry()
        activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .zipping)
        processingTask = Task { [weak self] in
            await self?.fullProcess(encoder: encoder, houseId: houseId)
        }
    }

    /// 앱 재시작 시 폴링 재개용
    func startProcessing(scanId: Int, houseId: Int) {
        savePendingScan(scanId: scanId, houseId: houseId)
        activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
        cancelProcessingTask()
        processingTask = Task { [weak self] in
            await self?.pollAndDownload(scanId: scanId, houseId: houseId)
        }
    }

    /// 진행 중인 스캔 취소
    func cancel() {
        let scanId = activeScan?.scanId ?? 0
        cancelProcessingTask()
        activeScan = nil
        clearPendingScan()
        discardPendingRetry()

        if scanId > 0 {
            Task { [weak self] in
                try? await self?.scanRepository?.cancelScan(scanId: scanId)
            }
        }
    }

    /// 완료된 스캔 소비 (저장 완료 후 호출)
    func clear() {
        cancelProcessingTask()
        activeScan = nil
        clearPendingScan()
        discardPendingRetry()
    }

    /// 실패 후 사용 가능한 재시도 여부.
    /// `activeScan`이 `.failed` 상태이고 보관된 retry의 houseId가 일치할 때만 true.
    var canRetry: Bool {
        guard let pendingRetry, let activeScan else { return false }
        guard case .failed = activeScan.phase else { return false }
        return activeScan.houseId == pendingRetry.houseId
    }

    /// 실패 지점에 맞는 방식으로 재시도.
    /// 업로드 실패는 보존된 zip 재업로드, 다운로드 실패는 동일 scanId 재다운로드.
    func retry() {
        guard let pendingRetry, canRetry else { return }
        let houseId = pendingRetry.houseId
        cancelProcessingTask()

        switch pendingRetry.source {
        case .upload(let zipURL):
            activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .uploading)
            processingTask = Task { [weak self] in
                await self?.retryUploadProcess(zipURL: zipURL, houseId: houseId)
            }
        case .polling(let scanId):
            // 다시 실패하면 pollAndDownload가 pendingRetry를 재설정한다
            self.pendingRetry = nil
            activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
            processingTask = Task { [weak self] in
                await self?.pollAndDownload(scanId: scanId, houseId: houseId)
            }
        case .download(let scanId):
            // 다시 실패하면 downloadPreview가 pendingRetry를 재설정한다
            self.pendingRetry = nil
            activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
            processingTask = Task { [weak self] in
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

    /// 앱 lifecycle 전환 시 호출.
    /// `.inactive`(전화 배너, 제어센터 등)에서도 폴링을 멈추는 것은 의도된 정책 —
    /// `.active` 복귀 시 대기 중인 루프를 즉시 깨워 바로 폴링하므로 짧은 중단에도 재개 지연이 없다.
    func handleScenePhase(_ phase: ScenePhase) {
        isInBackground = (phase != .active)
        if !isInBackground {
            wakeForegroundWaiter()
        }
    }

    #if DEBUG
    func setActiveScan(_ scan: ActiveScan?) {
        activeScan = scan
    }

    func setPendingRetry(houseId: Int, source: RetrySource) {
        pendingRetry = PendingRetry(houseId: houseId, source: source)
    }
    #endif

    // MARK: - Task Lifecycle

    /// 진행 중인 폴링 Task를 취소하고, 백그라운드 대기 중이면 깨워서 취소를 인지시킨다
    private func cancelProcessingTask() {
        processingTask?.cancel()
        wakeForegroundWaiter()
    }

    private func wakeForegroundWaiter() {
        foregroundWaiter?.resume()
        foregroundWaiter = nil
    }

    /// 백그라운드 동안 폴링 루프를 재우고 포그라운드 복귀(또는 Task 취소) 시 즉시 깨어난다
    private func waitUntilForeground() async {
        await withCheckedContinuation { continuation in
            foregroundWaiter = continuation
        }
    }

    // MARK: - Persistence

    private func savePendingScan(scanId: Int, houseId: Int) {
        userDefaults.set(scanId, forKey: Defaults.scanIdKey)
        userDefaults.set(houseId, forKey: Defaults.houseIdKey)
    }

    private func clearPendingScan() {
        userDefaults.removeObject(forKey: Defaults.scanIdKey)
        userDefaults.removeObject(forKey: Defaults.houseIdKey)
    }

    /// 앱 재시작 시 저장된 스캔이 있으면 폴링 재개
    private func resumeIfNeeded() {
        let scanId = userDefaults.integer(forKey: Defaults.scanIdKey)
        let houseId = userDefaults.integer(forKey: Defaults.houseIdKey)
        guard scanId > 0, houseId > 0 else { return }

        activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
        cancelProcessingTask()
        processingTask = Task { [weak self] in
            await self?.pollAndDownload(scanId: scanId, houseId: houseId)
        }
    }

    // MARK: - Full Process

    private func fullProcess(encoder: DatasetEncoder, houseId: Int) async {
        guard let scanRepository else { return }

        // 1. WrapUp
        await encoder.wrapUp()
        if Task.isCancelled { return }

        // 2. Zip — 대용량 데이터셋의 동기 압축이라 메인 스레드에서 수행하면 UI가 멈춘다
        let datasetDir = encoder.datasetDirectoryURL
        let zipURL = datasetDir.deletingLastPathComponent().appendingPathComponent("\(encoder.id.uuidString).zip")
        do {
            try await Task.detached(priority: .userInitiated) {
                try FileManager.default.zipItem(at: datasetDir, to: zipURL, shouldKeepParent: false)
            }.value
        } catch {
            activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .failed("압축 실패: \(error.localizedDescription)"))
            return
        }
        if Task.isCancelled { cleanup(zipURL: zipURL, datasetDir: datasetDir); return }

        // 3. Upload
        activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .uploading)
        let scanResult: ScanResult
        do {
            scanResult = try await scanRepository.uploadScan(houseId: houseId, fileURL: zipURL)
        } catch {
            if Task.isCancelled {
                cleanup(zipURL: zipURL, datasetDir: datasetDir)
                return
            }
            // 재시도 가능하도록 zip은 보존하고 datasetDir만 정리
            try? FileManager.default.removeItem(at: datasetDir)
            pendingRetry = PendingRetry(houseId: houseId, source: .upload(zipURL: zipURL))
            activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .failed("업로드 실패: \(error.localizedDescription)"))
            return
        }
        cleanup(zipURL: zipURL, datasetDir: datasetDir)
        if Task.isCancelled { return }

        // 4. Poll + Download
        let scanId = scanResult.scanId
        savePendingScan(scanId: scanId, houseId: houseId)
        activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
        await pollAndDownload(scanId: scanId, houseId: houseId)
    }

    private func cleanup(zipURL: URL, datasetDir: URL) {
        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: datasetDir)
    }

    private func discardPendingRetry() {
        guard let pendingRetry else { return }
        if case .upload(let zipURL) = pendingRetry.source {
            try? FileManager.default.removeItem(at: zipURL)
        }
        self.pendingRetry = nil
    }

    // MARK: - Retry

    private func retryUploadProcess(zipURL: URL, houseId: Int) async {
        guard let scanRepository else { return }
        let scanResult: ScanResult
        do {
            scanResult = try await scanRepository.uploadScan(houseId: houseId, fileURL: zipURL)
        } catch {
            if Task.isCancelled { return }
            activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .failed("업로드 실패: \(error.localizedDescription)"))
            return
        }
        try? FileManager.default.removeItem(at: zipURL)
        pendingRetry = nil
        if Task.isCancelled { return }

        let scanId = scanResult.scanId
        savePendingScan(scanId: scanId, houseId: houseId)
        activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
        await pollAndDownload(scanId: scanId, houseId: houseId)
    }

    // MARK: - Poll & Download

    private func pollAndDownload(scanId: Int, houseId: Int) async {
        guard let scanRepository else { return }

        // Poll until completed
        var attempts = 0
        var consecutiveErrors = 0
        while !Task.isCancelled {
            // 백그라운드 상태에서는 API 호출을 멈추고 포그라운드 복귀까지 대기
            if isInBackground {
                await waitUntilForeground()
                continue
            }

            attempts += 1
            if attempts > pollConfig.maxAttempts {
                try? await scanRepository.cancelScan(scanId: scanId)
                activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("처리 시간이 초과되었습니다"))
                clearPendingScan()
                return
            }

            do {
                let status = try await scanRepository.getScanStatus(scanId: scanId).uppercased()
                consecutiveErrors = 0
                #if DEBUG
                print("[ScanProcessing] scanId=\(scanId) status=\(status)")
                #endif
                if status == "COMPLETED" {
                    break
                } else if status == "FAILED" {
                    activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("서버에서 스캔 처리에 실패했습니다"))
                    clearPendingScan()
                    return
                }
            } catch {
                if Task.isCancelled { return }
                consecutiveErrors += 1
                if consecutiveErrors >= pollConfig.maxConsecutiveErrors {
                    // 일시적 네트워크 문제일 수 있는 비확정 실패 — pending을 유지해
                    // 재시도(재폴링)와 앱 재시작 복구가 가능하게 한다
                    pendingRetry = PendingRetry(houseId: houseId, source: .polling(scanId: scanId))
                    activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("상태 조회 실패: \(error.localizedDescription)"))
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
            guard let remoteURL = URL(string: fileURLString) else {
                pendingRetry = PendingRetry(houseId: houseId, source: .download(scanId: scanId))
                activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("잘못된 파일 URL"))
                return
            }
            let localURL = try await fileCache.download(from: remoteURL, roomId: scanId)
            activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .completed(fileURL: localURL))
        } catch {
            if Task.isCancelled { return }
            pendingRetry = PendingRetry(houseId: houseId, source: .download(scanId: scanId))
            activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("프리뷰 다운로드 실패: \(error.localizedDescription)"))
        }
    }
}
