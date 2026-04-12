//
//  IMUEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation

final class IMUEncoder {
    private let path: URL
    private let fileHandle: FileHandle

    init(url: URL) throws {
        self.path = url
        try "".write(to: url, atomically: true, encoding: .utf8)
        self.fileHandle = try FileHandle(forWritingTo: url)
        fileHandle.write("timestamp, a_x, a_y, a_z, alpha_x, alpha_y, alpha_z\n".data(using: .utf8)!)
    }

    func add(timestamp: Double, linear: simd_double3, angular: simd_double3) {
        let line = "\(timestamp), \(linear.x), \(linear.y), \(linear.z), \(angular.x), \(angular.y), \(angular.z)\n"
        fileHandle.write(line.data(using: .utf8)!)
    }

    func done() {
        do {
            try fileHandle.close()
        } catch {
            print("IMUEncoder: 파일 닫기 실패. \(error.localizedDescription)")
        }
    }
}
