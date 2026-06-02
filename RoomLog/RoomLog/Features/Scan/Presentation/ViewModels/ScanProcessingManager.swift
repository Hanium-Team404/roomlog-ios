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

    /// 업로드 실패 후 재시도용 zip과 그 소유 houseId를 함께 보관.
    /// 다른 집의 새 스캔이 시작돼도 cross-house 업로드가 일어나지 않도록 한 단위로 묶는다.
    private struct PendingRetry {
        let houseId: Int
        let zipURL: URL
    }

    // MARK: - Persistence Keys

    private enum Defaults {
        static let scanIdKey = "ScanProcessing_scanId"
        static let houseIdKey = "ScanProcessing_houseId"
    }

    // MARK: - State

    private(set) var activeScan: ActiveScan?
    /// 업로드 실패 후 재시도용 정보. nil이면 재시도 불가.
    private var pendingRetry: PendingRetry?

    // MARK: - Dependencies

    private var scanRepository: ScanRepositoryProtocol?
    private let fileCache = PLYFileCache.shared
    private var processingTask: Task<Void, Never>?
    private var isInBackground = false

    // MARK: - Setup

    func configure(scanRepository: ScanRepositoryProtocol) {
        self.scanRepository = scanRepository
        resumeIfNeeded()
    }

    // MARK: - Public

    /// 촬영 완료 후 호출. wrapUp → 압축 → 업로드 → 폴링 → 다운로드 전체 수행.
    @MainActor
    func startFullProcess(encoder: DatasetEncoder, houseId: Int) {
        processingTask?.cancel()
        activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .zipping)
        processingTask = Task { [weak self] in
            await self?.fullProcess(encoder: encoder, houseId: houseId)
        }
    }

    /// 앱 재시작 시 폴링 재개용
    @MainActor
    func startProcessing(scanId: Int, houseId: Int) {
        savePendingScan(scanId: scanId, houseId: houseId)
        activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
        processingTask?.cancel()
        processingTask = Task { [weak self] in
            await self?.pollAndDownload(scanId: scanId, houseId: houseId)
        }
    }

    /// 진행 중인 스캔 취소
    @MainActor
    func cancel() {
        let scanId = activeScan?.scanId ?? 0
        processingTask?.cancel()
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
    @MainActor
    func clear() {
        processingTask?.cancel()
        activeScan = nil
        clearPendingScan()
        discardPendingRetry()
    }

    /// 업로드 실패 후 사용 가능한 재시도 여부.
    /// `activeScan`이 `.failed` 상태이고 보관된 retry의 houseId가 일치할 때만 true.
    @MainActor
    var canRetryUpload: Bool {
        guard let pendingRetry, let activeScan else { return false }
        guard case .failed = activeScan.phase else { return false }
        return activeScan.houseId == pendingRetry.houseId
    }

    /// 업로드 실패 후 동일한 zip으로 업로드 재시도
    @MainActor
    func retryUpload() {
        guard let pendingRetry,
              let scan = activeScan,
              scan.houseId == pendingRetry.houseId else { return }
        let houseId = pendingRetry.houseId
        let zipURL = pendingRetry.zipURL
        processingTask?.cancel()
        activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .uploading)
        processingTask = Task { [weak self] in
            await self?.retryUploadProcess(zipURL: zipURL, houseId: houseId)
        }
    }

    /// 특정 houseId에 완료된 스캔이 있는지 확인
    @MainActor
    func completedScan(for houseId: Int) -> ActiveScan? {
        guard let scan = activeScan,
              scan.houseId == houseId,
              case .completed = scan.phase else {
            return nil
        }
        return scan
    }

    /// 특정 houseId에 진행 중인 스캔이 있는지 확인
    @MainActor
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
    @MainActor
    func handleScenePhase(_ phase: ScenePhase) {
        isInBackground = (phase != .active)
    }

    #if DEBUG
    func setActiveScan(_ scan: ActiveScan?) {
        activeScan = scan
    }
    #endif

    // MARK: - Persistence

    private func savePendingScan(scanId: Int, houseId: Int) {
        UserDefaults.standard.set(scanId, forKey: Defaults.scanIdKey)
        UserDefaults.standard.set(houseId, forKey: Defaults.houseIdKey)
    }

    private func clearPendingScan() {
        UserDefaults.standard.removeObject(forKey: Defaults.scanIdKey)
        UserDefaults.standard.removeObject(forKey: Defaults.houseIdKey)
    }

    /// 앱 재시작 시 저장된 스캔이 있으면 폴링 재개
    private func resumeIfNeeded() {
        let scanId = UserDefaults.standard.integer(forKey: Defaults.scanIdKey)
        let houseId = UserDefaults.standard.integer(forKey: Defaults.houseIdKey)
        guard scanId > 0, houseId > 0 else { return }

        activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .polling)
        processingTask?.cancel()
        processingTask = Task { [weak self] in
            await self?.pollAndDownload(scanId: scanId, houseId: houseId)
        }
    }

    // MARK: - Full Process

    @MainActor
    private func fullProcess(encoder: DatasetEncoder, houseId: Int) async {
        guard let scanRepository else { return }

        // 1. WrapUp
        await encoder.wrapUp()
        if Task.isCancelled { return }

        // 2. Zip
        let datasetDir = encoder.datasetDirectoryURL
        let zipURL = datasetDir.deletingLastPathComponent().appendingPathComponent("\(encoder.id.uuidString).zip")
        do {
            try FileManager.default.zipItem(at: datasetDir, to: zipURL, shouldKeepParent: false)
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
            pendingRetry = PendingRetry(houseId: houseId, zipURL: zipURL)
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

    @MainActor
    private func discardPendingRetry() {
        if let pendingRetry {
            try? FileManager.default.removeItem(at: pendingRetry.zipURL)
            self.pendingRetry = nil
        }
    }

    // MARK: - Retry

    @MainActor
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

    private enum PollConfig {
        static let maxAttempts = 60
        static let intervalSeconds = 7
        static let maxConsecutiveErrors = 3
    }

    @MainActor
    private func pollAndDownload(scanId: Int, houseId: Int) async {
        guard let scanRepository else { return }

        // Poll until completed
        var attempts = 0
        var consecutiveErrors = 0
        while !Task.isCancelled {
            // 백그라운드 상태에서는 API 호출을 건너뛰고 대기만 한다
            if isInBackground {
                try? await Task.sleep(for: .seconds(PollConfig.intervalSeconds))
                continue
            }

            attempts += 1
            if attempts > PollConfig.maxAttempts {
                try? await scanRepository.cancelScan(scanId: scanId)
                activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("처리 시간이 초과되었습니다"))
                clearPendingScan()
                return
            }

            do {
                let status = try await scanRepository.getScanStatus(scanId: scanId).uppercased()
                consecutiveErrors = 0
                print("[ScanProcessing] scanId=\(scanId) status=\(status)")
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
                if consecutiveErrors >= PollConfig.maxConsecutiveErrors {
                    activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("상태 조회 실패: \(error.localizedDescription)"))
                    clearPendingScan()
                    return
                }
            }
            try? await Task.sleep(for: .seconds(PollConfig.intervalSeconds))
        }

        if Task.isCancelled { return }

        // Download preview
        do {
            let fileURLString = try await scanRepository.getScanPreview(scanId: scanId)
            guard let remoteURL = URL(string: fileURLString) else {
                activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("잘못된 파일 URL"))
                clearPendingScan()
                return
            }
            let localURL = try await fileCache.download(from: remoteURL, roomId: scanId)
            activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .completed(fileURL: localURL))
        } catch {
            if Task.isCancelled { return }
            activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("프리뷰 다운로드 실패: \(error.localizedDescription)"))
            clearPendingScan()
        }
    }
}
