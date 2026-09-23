//
//  DatasetEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//
//  Based on Stray Scanner (https://github.com/strayrobots/scanner)
//  Copyright (c) 2021 Stray Robots — MIT License
//

import Foundation
import ARKit
import CoreMotion
import Synchronization

/// ARFrame에서 인코딩에 필요한 데이터만 추출한 스냅샷.
/// Task 체인이 ARFrame 전체를 보유하면 ARKit의 고정 크기 프레임 풀이 고갈되어
/// 카메라 프레임 공급이 중단되므로, 필요한 버퍼만 남기고 ARFrame은 즉시 해제한다.
/// CVPixelBuffer는 캡처 이후 읽기 전용으로만 접근하므로 스레드 간 전달이 안전하다.
private nonisolated struct FramePayload: @unchecked Sendable {
    let capturedImage: CVPixelBuffer
    let depthMap: CVPixelBuffer?
    let confidenceMap: CVPixelBuffer?
    let timestamp: TimeInterval
    let transform: simd_float4x4
}

/// 스캔 데이터셋 인코딩 진입점.
///
/// 동시성 구조:
/// - 모든 메서드는 main thread에서 호출된다 (ARSession delegate와 CMMotionManager 콜백 모두 main 큐).
///   mutable 상태(currentFrame, savedFrames, lastTask, isFinalizing 등)도 main에서만 접근한다.
/// - 실제 인코딩은 detached Task 직렬 체인에서 백그라운드로 수행된다. 각 Task가 이전 Task의
///   완료를 await하므로 프레임 순서가 보장되고, 하위 인코더들은 이 체인 안에서만 접근된다.
///   이 두 불변식이 @unchecked Sendable의 근거다.
nonisolated final class DatasetEncoder: @unchecked Sendable {
    enum Status {
        case allGood
        case videoEncodingError
    }

    /// 인코딩 대기 프레임 상한. 초과분은 드롭해 인코딩 지연 시 버퍼 보유가 무한정 쌓이지 않게 한다.
    private static let maxPendingFrames = 3

    /// 인코딩 대기 키프레임 상한. JPEG 인코딩이 키프레임 간격보다 느려질 때
    /// 복사된 픽셀 버퍼(장당 약 4MB)가 무한정 쌓이지 않게 한다.
    private static let maxPendingKeyframes = 2

    /// 키프레임 선정 파라미터. 임계값은 실측 후 조정 가능하도록 상수로 분리.
    private enum KeyframeSelection {
        /// 목표 저장 간격 (초)
        static let targetInterval: TimeInterval = 0.5
        /// 이 값(rad/s) 미만이면 흔들림이 적은 순간으로 판단
        static let gyroThreshold: Double = 0.3
        /// 이 시간(초) 내내 흔들렸으면 공백 방지를 위해 그냥 저장
        static let timeout: TimeInterval = 1.5
    }

    private let rgbEncoder: VideoEncoder
    private let depthEncoder: DepthEncoder
    private let confidenceEncoder: ConfidenceEncoder
    private let odometryEncoder: OdometryEncoder
    private let imuEncoder: IMUEncoder
    private let keyframeEncoder: KeyframeEncoder
    private let datasetDirectory: URL
    private var lastTask: Task<Void, Never>?
    /// 키프레임 JPEG 인코딩 전용 직렬 체인. 인코딩이 느려도(수백 ms) ARFrame을 붙잡지 않도록
    /// 메인 체인(lastTask)과 분리하고, 복사된 픽셀 버퍼만 넘긴다.
    private var lastKeyframeTask: Task<Void, Never>?
    private var isFinalizing = false
    private let frameInterval: Int
    private let imuLock = NSLock()
    /// main(증가)과 인코딩 체인(감소) 양쪽에서 접근하므로 Mutex로 보호한다.
    private let pendingFrames = Mutex(0)
    /// main(증가)과 키프레임 체인(감소) 양쪽에서 접근하므로 Mutex로 보호한다.
    private let pendingKeyframes = Mutex(0)
    private var currentFrame: Int = -1
    private var savedFrames: Int = 0
    private var latestIntrinsics: simd_float3x3?
    private var lastKeyframeTime: TimeInterval = 0
    private var latestAccelerometerData: (timestamp: Double, data: simd_double3)?
    private var latestGyroscopeData: (timestamp: Double, data: simd_double3)?
    /// 키프레임 전용 최신 각속도 (rad/s). `latestGyroscopeData`는 imu.csv 기록 시 페어링 후 nil로 소비되므로,
    /// 그 타이밍과 무관하게 "그 순간의 최신 각속도"를 유지하는 별도 값을 둔다. `imuLock`으로 보호.
    private var latestGyroForKeyframe: simd_double3 = .zero

    // 녹화 완료 후 외부에서 접근하는 프로퍼티
    let datasetDirectoryURL: URL
    let rgbFilePath: URL
    let depthFilePath: URL
    let cameraMatrixPath: URL
    let odometryPath: URL
    let imuPath: URL
    var status: Status = .allGood

    /// - Parameter directory: 데이터셋을 기록할 빈 디렉토리. 생성·청소는 `ScanArtifactStore`가 관리한다.
    init(arConfiguration: ARWorldTrackingConfiguration, directory: URL, fpsDivider: Int = 1) throws {
        self.frameInterval = max(1, fpsDivider)

        let width = arConfiguration.videoFormat.imageResolution.width
        let height = arConfiguration.videoFormat.imageResolution.height

        self.datasetDirectory = directory
        self.datasetDirectoryURL = directory

        self.rgbFilePath = directory.appendingPathComponent("rgb.mp4")
        self.rgbEncoder = VideoEncoder(file: rgbFilePath, width: width, height: height)

        self.depthFilePath = directory.appendingPathComponent("depth", isDirectory: true)
        self.depthEncoder = DepthEncoder(outDirectory: depthFilePath)

        let confidencePath = directory.appendingPathComponent("confidence", isDirectory: true)
        self.confidenceEncoder = ConfidenceEncoder(outDirectory: confidencePath)

        self.cameraMatrixPath = directory.appendingPathComponent("camera_matrix.csv")
        self.odometryPath = directory.appendingPathComponent("odometry.csv")
        self.odometryEncoder = try OdometryEncoder(url: odometryPath)

        self.imuPath = directory.appendingPathComponent("imu.csv")
        self.imuEncoder = try IMUEncoder(url: imuPath)

        self.keyframeEncoder = try KeyframeEncoder(
            imagesDirectory: directory.appendingPathComponent("keyframes", isDirectory: true),
            csvURL: directory.appendingPathComponent("keyframes.csv")
        )
    }

    func add(frame: ARFrame) {
        guard !isFinalizing else { return }
        guard case .normal = frame.camera.trackingState else { return }
        currentFrame += 1
        guard currentFrame % frameInterval == 0 else { return }

        // Backpressure: 인코딩이 프레임 유입을 따라가지 못하면 이번 프레임은 드롭한다
        let isBacklogged = pendingFrames.withLock { (count: inout Int) -> Bool in
            guard count < Self.maxPendingFrames else { return true }
            count += 1
            return false
        }
        if isBacklogged { return }

        let frameNumber = savedFrames
        savedFrames += 1
        latestIntrinsics = frame.camera.intrinsics

        let payload = FramePayload(
            capturedImage: frame.capturedImage,
            depthMap: frame.sceneDepth?.depthMap,
            confidenceMap: frame.sceneDepth?.confidenceMap,
            timestamp: frame.timestamp,
            transform: frame.camera.transform
        )

        // 각속도는 add(frame:) 시점에 동기로 캡처한다. Task 실행 시점에 읽으면 다른 순간의 값이 기록됨.
        imuLock.lock()
        let gyro = latestGyroForKeyframe
        imuLock.unlock()
        let gyroMagnitude = simd_length(gyro)

        let elapsed = frame.timestamp - lastKeyframeTime
        let isKeyframe = (elapsed >= KeyframeSelection.targetInterval && gyroMagnitude < KeyframeSelection.gyroThreshold)
            || elapsed >= KeyframeSelection.timeout
        if isKeyframe {
            // Backpressure: JPEG 인코딩이 키프레임 유입을 따라가지 못하면 이번 키프레임은 드롭한다.
            // 증가는 main에서만 일어나므로 검사-증가 사이에 상한을 넘을 일이 없다.
            let isKeyframeBacklogged = pendingKeyframes.withLock { $0 >= Self.maxPendingKeyframes }
            // 픽셀 버퍼를 즉시 복사하고 메타데이터만 뽑아서 ARFrame은 바로 놓아준다.
            // 원본 capturedImage를 JPEG 인코딩 동안 보관하면 카메라 버퍼 풀이 고갈되어 프레임 공급이 멈춘다.
            // 드롭되거나 복사에 실패하면 lastKeyframeTime을 갱신하지 않아 다음 프레임에서 다시 시도한다.
            if !isKeyframeBacklogged, let pixelBufferCopy = KeyframeEncoder.copyPixelBuffer(frame.capturedImage) {
                lastKeyframeTime = frame.timestamp
                pendingKeyframes.withLock { $0 += 1 }
                let keyframe = KeyframeEncoder.Keyframe(
                    pixelBuffer: pixelBufferCopy,
                    frameNumber: frameNumber,
                    timestamp: frame.timestamp,
                    intrinsics: frame.camera.intrinsics,
                    exposureDuration: frame.camera.exposureDuration,
                    exposureOffset: frame.camera.exposureOffset,
                    gyroMagnitude: gyroMagnitude
                )
                let previousKeyframe = lastKeyframeTask
                lastKeyframeTask = Task(priority: .utility) { [weak self] in
                    await previousKeyframe?.value
                    guard let self else { return }
                    defer { self.pendingKeyframes.withLock { $0 -= 1 } }
                    self.keyframeEncoder.encode(keyframe)
                }
            }
        }

        let previous = lastTask
        lastTask = Task.detached(priority: .utility) { [weak self] in
            await previous?.value
            guard let self else { return }
            defer { self.pendingFrames.withLock { $0 -= 1 } }
            if let depthMap = payload.depthMap {
                self.depthEncoder.encodeFrame(frame: depthMap, frameNumber: frameNumber)
                if let confidenceMap = payload.confidenceMap {
                    self.confidenceEncoder.encodeFrame(frame: confidenceMap, frameNumber: frameNumber)
                }
            }
            await self.rgbEncoder.add(
                frame: VideoEncoderInput(buffer: payload.capturedImage, time: payload.timestamp)
            )
            self.odometryEncoder.add(
                timestamp: payload.timestamp,
                transform: payload.transform,
                currentFrame: frameNumber
            )
        }
    }

    // IMU 콜백은 전용 큐(ScanViewModel.imuQueue)에서 들어오므로, isFinalizing 검사도
    // imuLock 안에서 해야 wrapUp()의 imu.csv 닫기와 겹치지 않는다.
    func addRawAccelerometer(data: CMAccelerometerData) {
        imuLock.lock()
        defer { imuLock.unlock() }
        guard !isFinalizing else { return }
        let acceleration = simd_double3(data.acceleration.x, data.acceleration.y, data.acceleration.z)
        latestAccelerometerData = (timestamp: data.timestamp, data: acceleration)
        tryWritingIMUData()
    }

    func addRawGyroscope(data: CMGyroData) {
        imuLock.lock()
        defer { imuLock.unlock() }
        guard !isFinalizing else { return }
        let rotationRate = simd_double3(data.rotationRate.x, data.rotationRate.y, data.rotationRate.z)
        latestGyroscopeData = (timestamp: data.timestamp, data: rotationRate)
        latestGyroForKeyframe = rotationRate
        tryWritingIMUData()
    }

    func wrapUp() async {
        // 진행 중인 IMU 콜백이 끝난 뒤에 플래그가 서도록 락 안에서 갱신한다.
        // (이후 imuEncoder.done()으로 파일을 닫을 때 쓰기와 충돌하지 않음)
        imuLock.lock()
        isFinalizing = true
        imuLock.unlock()

        await lastTask?.value
        lastTask = nil
        await lastKeyframeTask?.value
        lastKeyframeTask = nil

        await rgbEncoder.finishEncoding()

        do {
            try imuEncoder.done()
        } catch {
            #if DEBUG
            print("DatasetEncoder: IMU 파일 닫기 실패. \(error.localizedDescription)")
            #endif
            status = .videoEncodingError
        }

        odometryEncoder.done()
        keyframeEncoder.done()
        writeIntrinsics()

        if case .error = rgbEncoder.status { status = .videoEncodingError }
        if case .frameEncodingError = depthEncoder.status { status = .videoEncodingError }
        if case .encodingError = confidenceEncoder.status { status = .videoEncodingError }
        if case .encodingError = keyframeEncoder.status { status = .videoEncodingError }
    }

    // MARK: - Private

    private func tryWritingIMUData() {
        guard let accelerometer = latestAccelerometerData,
              let gyroscope = latestGyroscopeData else { return }

        let timestamp = max(accelerometer.timestamp, gyroscope.timestamp)
        imuEncoder.add(timestamp: timestamp, linear: accelerometer.data, angular: gyroscope.data)

        latestAccelerometerData = nil
        latestGyroscopeData = nil
    }

    private func writeIntrinsics() {
        guard let cameraMatrix = latestIntrinsics else { return }
        let rows = cameraMatrix.transpose.columns
        let csv = [rows.0, rows.1, rows.2].map { "\($0.x), \($0.y), \($0.z)" }.joined(separator: "\n")
        do {
            try csv.write(to: cameraMatrixPath, atomically: true, encoding: .utf8)
        } catch {
            #if DEBUG
            print("DatasetEncoder: could not write camera matrix. \(error.localizedDescription)")
            #endif
            status = .videoEncodingError
        }
    }
}
