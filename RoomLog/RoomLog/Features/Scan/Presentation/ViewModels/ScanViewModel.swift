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
    private(set) var showDepthWarning: Bool = false
    /// AR 세션이 실패해 재시작 중일 때 true. 재시작 후 첫 프레임이 도착하면 해제된다.
    private(set) var showSessionError: Bool = false
    /// 세션 실패 시각 (uptime 기준). 에러 이전에 캡처돼 큐에 남아 있던 프레임이
    /// 배너를 조기 해제하지 않도록, 이 시각 이후 프레임만 해제 조건으로 인정한다.
    private var sessionErrorUptime: TimeInterval = 0
    private var warningFrames: Int = 0
    private var okFrames: Int = 0
    private var totalFrameCount: Int = 0
    private var isPreview: Bool = false

    let session = ARSession()
    let houseId: Int

    private let processingManager: ScanProcessingManager
    private let onStartConversion: () -> Void
    private var recordingTimer: Timer?

    private let configuration: ARWorldTrackingConfiguration = {
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics = .sceneDepth
        }
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        return config
    }()

    private let motionManager = CMMotionManager()
    private var encoder: DatasetEncoder?

    // MARK: - Init

    init(
        houseId: Int,
        processingManager: ScanProcessingManager,
        onStartConversion: @escaping () -> Void
    ) {
        self.houseId = houseId
        self.processingManager = processingManager
        self.onStartConversion = onStartConversion
        super.init()
    }

    #if DEBUG
    convenience init(preview phase: Phase) {
        self.init(
            houseId: 0,
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
        prepareEncoder()
    }

    private func prepareEncoder() {
        do {
            encoder = try DatasetEncoder(arConfiguration: configuration)
        } catch {
            #if DEBUG
            print("ScanViewModel: 인코더 사전 준비 실패. \(error.localizedDescription)")
            #endif
        }
    }

    func tearDown() {
        stopIMU()
        session.pause()
    }

    // MARK: - Recording

    func startRecording() {
        if encoder == nil { prepareEncoder() }
        guard encoder != nil else { return }
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
            houseId: houseId
        )
        self.encoder = nil
        onStartConversion()
    }

    func reset() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        encoder = nil
        phase = .idle
        prepareEncoder()
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
        if showSessionError, frame.timestamp > sessionErrorUptime {
            showSessionError = false
        }
        updateDepthWarning(frame: frame)
        guard phase == .recording else { return }
        encoder?.add(frame: frame)
    }

    /// 카메라 등 필수 센서 실패 시 호출된다 (예: 이전 인스턴스가 카메라를 점유 중일 때 Code=102).
    /// 진행 중이던 녹화는 폐기하고 세션을 재시작해 복구를 시도한다.
    func session(_ session: ARSession, didFailWithError error: Error) {
        #if DEBUG
        print("ScanViewModel: AR 세션 실패, 재시작 시도. \(error.localizedDescription)")
        #endif
        showSessionError = true
        sessionErrorUptime = ProcessInfo.processInfo.systemUptime
        // 녹화 중 데이터는 재시작 후 좌표계가 달라지므로 폐기한다.
        // 촬영 완료(.recorded) 상태의 인코더는 변환 대기 데이터이므로 보존한다.
        if phase == .recording {
            stopIMU()
            reset()
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    private func updateDepthWarning(frame: ARFrame) {
        totalFrameCount += 1
        guard totalFrameCount > 60 else { return }

        guard let depthMap = frame.sceneDepth?.depthMap else {
            warningFrames += 1
            okFrames = 0
            if !showDepthWarning && warningFrames >= 10 {
                showDepthWarning = true
            }
            return
        }

        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(depthMap) else { return }
        let buffer = base.assumingMemoryBound(to: Float32.self)

        let cx = width / 2, cy = height / 2
        let range = width / 6
        let step = 3

        var samples: [Float] = []
        for y in stride(from: cy - range, to: cy + range, by: step) {
            for x in stride(from: cx - range, to: cx + range, by: step) {
                let d = buffer[y * width + x]
                if d > 0 && !d.isNaN && d < 10 {
                    samples.append(d)
                }
            }
        }
        samples.sort()
        let medianDepth = samples.isEmpty ? 0 : samples[samples.count / 2]
        let isBad = medianDepth < 0.20

        if isBad {
            warningFrames += 1
            okFrames = 0
            if !showDepthWarning && warningFrames >= 10 {
                showDepthWarning = true
            }
        } else {
            okFrames += 1
            warningFrames = 0
            if showDepthWarning && okFrames >= 20 {
                showDepthWarning = false
            }
        }
    }
}
