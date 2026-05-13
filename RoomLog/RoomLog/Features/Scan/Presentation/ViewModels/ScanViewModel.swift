//
//  ScanViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 4/13/26.
//

import Foundation
import ARKit
import CoreMotion

@Observable
final class ScanViewModel: NSObject {

    // MARK: - Phase

    enum Phase {
        case idle
        case recording
        case recorded
    }

    // MARK: - Properties

    private(set) var phase: Phase = .idle
    private(set) var recordingSeconds: Int = 0
    private var isPreview: Bool = false

    let session = ARSession()
    let houseId: Int
    let scanType: String

    private let processingManager: ScanProcessingManager
    private let onStartConversion: () -> Void
    private var recordingTimer: Timer?

    private let configuration: ARWorldTrackingConfiguration = {
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics = .sceneDepth
        }
        return config
    }()

    private let motionManager = CMMotionManager()
    private var encoder: DatasetEncoder?

    // MARK: - Init

    init(
        houseId: Int,
        scanType: String,
        processingManager: ScanProcessingManager,
        onStartConversion: @escaping () -> Void
    ) {
        self.houseId = houseId
        self.scanType = scanType
        self.processingManager = processingManager
        self.onStartConversion = onStartConversion
        super.init()
    }

    #if DEBUG
    convenience init(preview phase: Phase) {
        self.init(
            houseId: 0,
            scanType: "IN",
            processingManager: ScanProcessingManager(),
            onStartConversion: {}
        )
        self.phase = phase
        self.isPreview = true
    }
    #endif

    // MARK: - Lifecycle

    func setup() {
        guard !isPreview else { return }
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
            return
        }
        startIMU()
        recordingSeconds = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingSeconds += 1
        }
        phase = .recording
    }

    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        stopIMU()
        phase = .recorded
    }

    func startConversion() {
        guard let encoder else { return }
        processingManager.startFullProcess(
            encoder: encoder,
            houseId: houseId,
            scanType: scanType
        )
        self.encoder = nil
        onStartConversion()
    }

    func reset() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        encoder = nil
        phase = .idle
    }

    // MARK: - IMU

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
