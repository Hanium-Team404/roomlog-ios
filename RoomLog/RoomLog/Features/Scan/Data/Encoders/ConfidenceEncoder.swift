//
//  ConfidenceEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation
import CoreImage

final class ConfidenceEncoder {
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
            print("ConfidenceEncoder: 디렉토리 생성 실패. \(error.localizedDescription)")
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
            print("ConfidenceEncoder: PNG 저장 실패 (frame \(frameNumber)). \(error.localizedDescription)")
            status = .encodingError
        }
    }
}
