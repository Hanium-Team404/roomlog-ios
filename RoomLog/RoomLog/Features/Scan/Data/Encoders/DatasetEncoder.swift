//
//  DatasetEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
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
    private var dispatchGroup = DispatchGroup()
    private let queue: DispatchQueue
    private let frameInterval: Int
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

    init(arConfiguration: ARWorldTrackingConfiguration, fpsDivider: Int = 1) {
        self.frameInterval = fpsDivider
        self.queue = DispatchQueue(label: "com.roomlog.encoderQueue")

        let width = arConfiguration.videoFormat.imageResolution.width
        let height = arConfiguration.videoFormat.imageResolution.height

        var theId = UUID()
        let directory = DatasetEncoder.createDirectory(id: &theId)
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
        self.odometryEncoder = OdometryEncoder(url: odometryPath)

        self.imuPath = directory.appendingPathComponent("imu.csv")
        self.imuEncoder = IMUEncoder(url: imuPath)
    }

    func add(frame: ARFrame) {
        currentFrame += 1
        guard currentFrame % frameInterval == 0 else { return }

        let frameNumber = savedFrames
        let totalFrames = currentFrame
        savedFrames += 1

        dispatchGroup.enter()
        queue.async { [weak self] in
            guard let self else {
                self?.dispatchGroup.leave()
                return
            }
            if let sceneDepth = frame.sceneDepth {
                self.depthEncoder.encodeFrame(frame: sceneDepth.depthMap, frameNumber: frameNumber)
                if let confidence = sceneDepth.confidenceMap {
                    self.confidenceEncoder.encodeFrame(frame: confidence, frameNumber: frameNumber)
                }
            }
            self.rgbEncoder.add(
                frame: VideoEncoderInput(buffer: frame.capturedImage, time: frame.timestamp),
                currentFrame: totalFrames
            )
            self.odometryEncoder.add(frame: frame, currentFrame: frameNumber)
            self.lastFrame = frame
            self.dispatchGroup.leave()
        }
    }

    func addRawAccelerometer(data: CMAccelerometerData) {
        let acceleration = simd_double3(data.acceleration.x, data.acceleration.y, data.acceleration.z)
        latestAccelerometerData = (timestamp: data.timestamp, data: acceleration)
        tryWritingIMUData()
    }

    func addRawGyroscope(data: CMGyroData) {
        let rotationRate = simd_double3(data.rotationRate.x, data.rotationRate.y, data.rotationRate.z)
        latestGyroscopeData = (timestamp: data.timestamp, data: rotationRate)
        tryWritingIMUData()
    }

    func wrapUp() {
        dispatchGroup.wait()
        rgbEncoder.finishEncoding()
        imuEncoder.done()
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
            print("DatasetEncoder: could not write camera matrix. \(error.localizedDescription)")
        }
    }

    private static func createDirectory(id: inout UUID) -> URL {
        let directoryName = hashUUID(id: id)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directory = documentsURL.appendingPathComponent(directoryName, isDirectory: true)

        if FileManager.default.fileExists(atPath: directory.path) {
            id = UUID()
            return createDirectory(id: &id)
        }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            print("DatasetEncoder: could not create directory. \(error.localizedDescription)")
        }
        return directory
    }

    private static func hashUUID(id: UUID) -> String {
        var hasher = SHA256()
        hasher.update(data: id.uuidString.data(using: .ascii)!)
        let digest = hasher.finalize()
        return digest.prefix(5).map { String(format: "%02x", $0) }.joined()
    }
}
