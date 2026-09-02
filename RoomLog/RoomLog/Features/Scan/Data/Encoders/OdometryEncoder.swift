//
//  OdometryEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//
//  Based on Stray Scanner (https://github.com/strayrobots/scanner)
//  Copyright (c) 2021 Stray Robots — MIT License
//

import Foundation
import simd
import Accelerate

/// 카메라 포즈를 CSV로 기록하는 인코더.
/// DatasetEncoder의 직렬 인코딩 체인에서만 접근된다 (@unchecked Sendable 근거는 VideoEncoder 참고).
nonisolated final class OdometryEncoder: @unchecked Sendable {
    private let path: URL
    private let fileHandle: FileHandle
    private let q_AC = simd_quatf(ix: 1.0, iy: 0.0, iz: 0.0, r: 0.0)

    init(url: URL) throws {
        self.path = url
        try "".write(to: url, atomically: true, encoding: .utf8)
        self.fileHandle = try FileHandle(forWritingTo: url)
        try fileHandle.write(contentsOf: Data("timestamp, frame, x, y, z, qx, qy, qz, qw\n".utf8))
    }

    func add(timestamp: TimeInterval, transform: simd_float4x4, currentFrame: Int) {
        let t = transform[3]
        let xyz = vector_float3(t.x, t.y, t.z)
        let q = (simd_quatf(transform) * q_AC).vector
        let frameNumber = String(format: "%06d", currentFrame)
        let line = "\(timestamp), \(frameNumber), \(xyz.x), \(xyz.y), \(xyz.z), \(q.x), \(q.y), \(q.z), \(q.w)\n"
        try? fileHandle.write(contentsOf: Data(line.utf8))
    }

    func done() {
        do {
            try fileHandle.close()
        } catch {
            #if DEBUG
            print("OdometryEncoder: 파일 닫기 실패. \(error.localizedDescription)")
            #endif
        }
    }
}
