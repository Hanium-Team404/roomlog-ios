//
//  DepthEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation
import ARKit
import ImageIO

final class DepthEncoder {
    enum Status { case allGood, frameEncodingError }

    private let baseDirectory: URL
    var status: Status = .allGood

    init(outDirectory: URL) {
        self.baseDirectory = outDirectory
        do {
            try FileManager.default.createDirectory(at: outDirectory, withIntermediateDirectories: true)
        } catch {
            print("DepthEncoder: 디렉토리 생성 실패. \(error.localizedDescription)")
            status = .frameEncodingError
        }
    }

    func encodeFrame(frame: CVPixelBuffer, frameNumber: Int) {
        guard CVPixelBufferGetPixelFormatType(frame) == kCVPixelFormatType_DepthFloat32 else {
            status = .frameEncodingError
            return
        }

        let filename = String(format: "%06d.png", frameNumber)
        let framePath = baseDirectory.appendingPathComponent(filename)

        let width = CVPixelBufferGetWidth(frame)
        let height = CVPixelBufferGetHeight(frame)

        CVPixelBufferLockBaseAddress(frame, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(frame, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(frame) else {
            print("DepthEncoder: base address 접근 실패 (frame \(frameNumber))")
            status = .frameEncodingError
            return
        }

        let floatPtr = baseAddress.assumingMemoryBound(to: Float32.self)

        // Float32 meters → UInt16 millimeters, big-endian (PNG 표준)
        var uint16Pixels = [UInt16](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            let mm = floatPtr[i] * 1000.0
            guard mm.isFinite, mm >= 0 else {
                uint16Pixels[i] = 0
                continue
            }
            uint16Pixels[i] = UInt16(clamping: Int(mm.rounded())).bigEndian
        }

        let success = uint16Pixels.withUnsafeMutableBytes { rawPtr -> Bool in
            guard
                let context = CGContext(
                    data: rawPtr.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 16,
                    bytesPerRow: width * 2,
                    space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGBitmapInfo.byteOrder16Big.rawValue
                ),
                let cgImage = context.makeImage(),
                let dest = CGImageDestinationCreateWithURL(
                    framePath as CFURL,
                    "public.png" as CFString,
                    1, nil
                )
            else { return false }

            CGImageDestinationAddImage(dest, cgImage, nil)
            return CGImageDestinationFinalize(dest)
        }

        if !success {
            print("DepthEncoder: PNG 저장 실패 (frame \(frameNumber))")
            status = .frameEncodingError
        }
    }
}
