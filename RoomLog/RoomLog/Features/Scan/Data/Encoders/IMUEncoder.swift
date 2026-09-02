//
//  IMUEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//
//  Based on Stray Scanner (https://github.com/strayrobots/scanner)
//  Copyright (c) 2021 Stray Robots — MIT License
//

import Foundation
import simd

/// IMU 샘플을 CSV로 기록하는 인코더.
/// DatasetEncoder의 IMU 경로(main 큐 한정 CMMotionManager 콜백)에서만 접근된다.
nonisolated final class IMUEncoder {
    private let path: URL
    private let fileHandle: FileHandle

    init(url: URL) throws {
        self.path = url
        try "".write(to: url, atomically: true, encoding: .utf8)
        self.fileHandle = try FileHandle(forWritingTo: url)
        try fileHandle.write(contentsOf: Data("timestamp, a_x, a_y, a_z, alpha_x, alpha_y, alpha_z\n".utf8))
    }

    func add(timestamp: Double, linear: simd_double3, angular: simd_double3) {
        let line = "\(timestamp), \(linear.x), \(linear.y), \(linear.z), \(angular.x), \(angular.y), \(angular.z)\n"
        try? fileHandle.write(contentsOf: Data(line.utf8))
    }

    func done() throws {
        try fileHandle.close()
    }
}
