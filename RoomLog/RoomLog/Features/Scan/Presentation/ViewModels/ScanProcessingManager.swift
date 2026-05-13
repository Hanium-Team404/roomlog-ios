//
//  ScanProcessingManager.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation
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

    // MARK: - Persistence Keys

    private enum Defaults {
        static let scanIdKey = "ScanProcessing_scanId"
        static let houseIdKey = "ScanProcessing_houseId"
    }

    // MARK: - State

    private(set) var activeScan: ActiveScan?

    // MARK: - Dependencies

    private var scanRepository: ScanRepositoryProtocol?
    private let fileCache = PLYFileCache.shared
    private var processingTask: Task<Void, Never>?

    // MARK: - Setup

    func configure(scanRepository: ScanRepositoryProtocol) {
        self.scanRepository = scanRepository
        resumeIfNeeded()
    }

    // MARK: - Public

    /// 촬영 완료 후 호출. wrapUp → 압축 → 업로드 → 폴링 → 다운로드 전체 수행.
    @MainActor
    func startFullProcess(encoder: DatasetEncoder, houseId: Int, scanType: String) {
        processingTask?.cancel()
        activeScan = ActiveScan(scanId: 0, houseId: houseId, phase: .zipping)
        processingTask = Task { [weak self] in
            await self?.fullProcess(encoder: encoder, houseId: houseId, scanType: scanType)
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
        processingTask?.cancel()
        activeScan = nil
        clearPendingScan()
    }

    /// 완료된 스캔 소비 (저장 완료 후 호출)
    @MainActor
    func clear() {
        processingTask?.cancel()
        activeScan = nil
        clearPendingScan()
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
    private func fullProcess(encoder: DatasetEncoder, houseId: Int, scanType: String) async {
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
            scanResult = try await scanRepository.uploadScan(houseId: houseId, scanType: scanType, fileURL: zipURL)
        } catch {
            cleanup(zipURL: zipURL, datasetDir: datasetDir)
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

    // MARK: - Poll & Download

    @MainActor
    private func pollAndDownload(scanId: Int, houseId: Int) async {
        guard let scanRepository else { return }

        // Poll until completed
        while !Task.isCancelled {
            do {
                let status = try await scanRepository.getScanStatus(scanId: scanId).uppercased()
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
                activeScan = ActiveScan(scanId: scanId, houseId: houseId, phase: .failed("상태 조회 실패: \(error.localizedDescription)"))
                clearPendingScan()
                return
            }
            try? await Task.sleep(for: .seconds(7))
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
