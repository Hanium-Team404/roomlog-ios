//
//  ScanViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 4/13/26.
//

import Foundation
import ARKit
import CoreMotion
import ZIPFoundation

@Observable
final class ScanViewModel: NSObject {
    enum RecordingState {
        case idle
        case recording
        case processing
        case done(zipURL: URL)
        case failed(String)
    }

    // MARK: - Property

    private(set) var recordingState: RecordingState = .idle
    let session = ARSession()

    private let configuration: ARWorldTrackingConfiguration = {
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics = .sceneDepth
        }
        return config
    }()

    private let motionManager = CMMotionManager()
    private var encoder: DatasetEncoder?

    // MARK: - Lifecycle

    func setup() {
        session.delegate = self
        session.run(configuration)
    }

    func tearDown() {
        stopIMU()
        session.pause()
    }

    // MARK: - Recording

    func startRecording() {
        do {
            encoder = try DatasetEncoder(arConfiguration: configuration)
        } catch {
            recordingState = .failed(error.localizedDescription)
            return
        }
        startIMU()
        recordingState = .recording
    }

    func stopRecording() {
        stopIMU()
        recordingState = .processing
        Task { @MainActor [weak self] in
            guard let self else { return }
            await encoder?.wrapUp()
            await createZip()
        }
    }

    func reset() {
        if case .done(let url) = recordingState {
            try? FileManager.default.removeItem(at: url)
        }
        encoder = nil
        recordingState = .idle
    }

    // MARK: - Private

    private func createZip() async {
        guard let dir = encoder?.datasetDirectoryURL else {
            recordingState = .failed("데이터셋 경로 없음")
            return
        }
        let zipURL = dir.deletingLastPathComponent()
            .appendingPathComponent(dir.lastPathComponent + ".zip")
        do {
            try await Task.detached(priority: .utility) {
                try FileManager.default.zipItem(at: dir, to: zipURL)
            }.value
            recordingState = .done(zipURL: zipURL)
        } catch {
            recordingState = .failed("압축 실패: \(error.localizedDescription)")
        }
    }

    private func startIMU() {
        guard motionManager.isAccelerometerAvailable, motionManager.isGyroAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 100.0
        motionManager.gyroUpdateInterval = 1.0 / 100.0

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.encoder?.addRawAccelerometer(data: data)
        }
        motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.encoder?.addRawGyroscope(data: data)
        }
    }

    private func stopIMU() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }
}

// MARK: - ARSessionDelegate

extension ScanViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        encoder?.add(frame: frame)
    }
}
