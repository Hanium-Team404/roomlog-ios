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

final class DatasetEncoder {
    enum Status {
        case allGood
        case videoEncodingError
        case directoryCreationError
    }

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
    private var currentFrame: Int = -1
    private var savedFrames: Int = 0
    private var lastFrame: ARFrame?
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

        let frameNumber = savedFrames
        savedFrames += 1

        let previous = lastTask
        lastTask = Task(priority: .utility) { [weak self] in
            await previous?.value
            guard let self else { return }
            if let sceneDepth = frame.sceneDepth {
                depthEncoder.encodeFrame(frame: sceneDepth.depthMap, frameNumber: frameNumber)
                if let confidence = sceneDepth.confidenceMap {
                    confidenceEncoder.encodeFrame(frame: confidence, frameNumber: frameNumber)
                }
            }
            await rgbEncoder.add(
                frame: VideoEncoderInput(buffer: frame.capturedImage, time: frame.timestamp)
            )
            odometryEncoder.add(frame: frame, currentFrame: frameNumber)
            lastFrame = frame
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
        guard let cameraMatrix = lastFrame?.camera.intrinsics else { return }
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
