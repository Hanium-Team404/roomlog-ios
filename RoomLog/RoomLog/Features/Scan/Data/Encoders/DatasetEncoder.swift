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
import CryptoKit
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
        case directoryCreationError
    }

    /// 인코딩 대기 프레임 상한. 초과분은 드롭해 인코딩 지연 시 버퍼 보유가 무한정 쌓이지 않게 한다.
    private static let maxPendingFrames = 3

    private let rgbEncoder: VideoEncoder
    private let depthEncoder: DepthEncoder
    private let confidenceEncoder: ConfidenceEncoder
    private let odometryEncoder: OdometryEncoder
    private let imuEncoder: IMUEncoder
    private let datasetDirectory: URL
    private var lastTask: Task<Void, Never>?
    private var isFinalizing = false
    private let frameInterval: Int
    private let imuLock = NSLock()
    /// main(증가)과 인코딩 체인(감소) 양쪽에서 접근하므로 Mutex로 보호한다.
    private let pendingFrames = Mutex(0)
    private var currentFrame: Int = -1
    private var savedFrames: Int = 0
    private var latestIntrinsics: simd_float3x3?
    private var latestAccelerometerData: (timestamp: Double, data: simd_double3)?
    private var latestGyroscopeData: (timestamp: Double, data: simd_double3)?

    // 녹화 완료 후 외부에서 접근하는 프로퍼티
    let id: UUID
    let datasetDirectoryURL: URL
    let rgbFilePath: URL
    let depthFilePath: URL
    let cameraMatrixPath: URL
    let odometryPath: URL
    let imuPath: URL
    var status: Status = .allGood

    init(arConfiguration: ARWorldTrackingConfiguration, fpsDivider: Int = 1) throws {
        self.frameInterval = max(1, fpsDivider)

        let width = arConfiguration.videoFormat.imageResolution.width
        let height = arConfiguration.videoFormat.imageResolution.height

        var theId = UUID()
        let directory: URL
        do {
            directory = try DatasetEncoder.createDirectory(id: &theId)
        } catch {
            self.status = .directoryCreationError
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(theId.uuidString, isDirectory: true)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            directory = tempDir
        }
        self.id = theId
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

    func addRawAccelerometer(data: CMAccelerometerData) {
        guard !isFinalizing else { return }
        imuLock.lock()
        defer { imuLock.unlock() }
        let acceleration = simd_double3(data.acceleration.x, data.acceleration.y, data.acceleration.z)
        latestAccelerometerData = (timestamp: data.timestamp, data: acceleration)
        tryWritingIMUData()
    }

    func addRawGyroscope(data: CMGyroData) {
        guard !isFinalizing else { return }
        imuLock.lock()
        defer { imuLock.unlock() }
        let rotationRate = simd_double3(data.rotationRate.x, data.rotationRate.y, data.rotationRate.z)
        latestGyroscopeData = (timestamp: data.timestamp, data: rotationRate)
        tryWritingIMUData()
    }

    func wrapUp() async {
        isFinalizing = true

        await lastTask?.value
        lastTask = nil

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
        writeIntrinsics()

        if case .error = rgbEncoder.status { status = .videoEncodingError }
        if case .frameEncodingError = depthEncoder.status { status = .videoEncodingError }
        if case .encodingError = confidenceEncoder.status { status = .videoEncodingError }
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

    private static func createDirectory(id: inout UUID) throws -> URL {
        let directoryName = hashUUID(id: id)
        let documentsURL = URL.documentsDirectory
        let directory = documentsURL.appendingPathComponent(directoryName, isDirectory: true)

        if FileManager.default.fileExists(atPath: directory.path) {
            id = UUID()
            return try createDirectory(id: &id)
        }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func hashUUID(id: UUID) -> String {
        var hasher = SHA256()
        hasher.update(data: Data(id.uuidString.utf8))
        let digest = hasher.finalize()
        return digest.prefix(5).map { String(format: "%02x", $0) }.joined()
    }
}
