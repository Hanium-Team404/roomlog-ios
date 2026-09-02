//
//  ConfidenceEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//
//  Based on Stray Scanner (https://github.com/strayrobots/scanner)
//  Copyright (c) 2021 Stray Robots — MIT License
//

import Foundation
import CoreImage

/// Confidence 맵을 8-bit PNG로 저장하는 인코더.
/// DatasetEncoder의 직렬 인코딩 체인에서만 접근된다 (@unchecked Sendable 근거는 VideoEncoder 참고).
nonisolated final class ConfidenceEncoder: @unchecked Sendable {
    enum Status { case allGood, encodingError }

    private let baseDirectory: URL
    private let ciContext: CIContext
    var status: Status = .allGood

    init(outDirectory: URL) {
        self.baseDirectory = outDirectory
        self.ciContext = CIContext()
        do {
            try FileManager.default.createDirectory(at: outDirectory, withIntermediateDirectories: true)
        } catch {
            #if DEBUG
            print("ConfidenceEncoder: 디렉토리 생성 실패. \(error.localizedDescription)")
            #endif
            status = .encodingError
        }
    }

    func encodeFrame(frame: CVPixelBuffer, frameNumber: Int) {
        guard CVPixelBufferGetPixelFormatType(frame) == kCVPixelFormatType_OneComponent8 else {
            status = .encodingError
            return
        }
        let filename = String(format: "%06d.png", frameNumber)
        let framePath = baseDirectory.appendingPathComponent(filename)
        let image = CIImage(cvPixelBuffer: frame)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedGray) else {
            status = .encodingError
            return
        }
        do {
            try ciContext.writePNGRepresentation(of: image, to: framePath, format: .L8, colorSpace: colorSpace)
        } catch {
            #if DEBUG
            print("ConfidenceEncoder: PNG 저장 실패 (frame \(frameNumber)). \(error.localizedDescription)")
            #endif
            status = .encodingError
        }
    }
}
