//
//  KeyframeEncoder.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/13/26.
//

import Foundation
import ARKit
import CoreImage
import CoreVideo
import ImageIO

/// 흔들림이 적은 순간의 카메라 이미지를 고품질 JPEG 정지 이미지로 저장하고,
/// 키프레임별 메타데이터(intrinsics, 노출, 각속도)를 keyframes.csv에 기록한다.
/// 기존 rgb.mp4는 H.264 압축 손실과 모션 블러로 GS 학습 품질의 병목이라, 인코더를 거치지 않은 원본을 별도 보존한다.
final class KeyframeEncoder {
    enum Status { case allGood, encodingError }

    /// ARFrame에서 추출한 키프레임 데이터.
    /// pixelBuffer는 반드시 `copyPixelBuffer(_:)`로 만든 복사본이어야 한다.
    /// ARKit 카메라 버퍼 풀의 원본(capturedImage)을 JPEG 인코딩 동안 붙잡고 있으면
    /// 풀이 고갈되어 카메라가 프레임 공급을 중단한다 (화면 멈춤).
    struct Keyframe {
        let pixelBuffer: CVPixelBuffer
        let frameNumber: Int
        let timestamp: TimeInterval
        let intrinsics: simd_float3x3
        let exposureDuration: TimeInterval
        let exposureOffset: Float
        let gyroMagnitude: Double
    }

    private let imagesDirectory: URL
    private let fileHandle: FileHandle
    private let context = CIContext()
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private let jpegQuality: CGFloat = 0.9
    var status: Status = .allGood

    init(imagesDirectory: URL, csvURL: URL) throws {
        self.imagesDirectory = imagesDirectory
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        try "".write(to: csvURL, atomically: true, encoding: .utf8)
        self.fileHandle = try FileHandle(forWritingTo: csvURL)
        try fileHandle.write(contentsOf: Data("frame, timestamp, fx, fy, cx, cy, exposure_ms, exposure_offset, gyro_mag\n".utf8))
    }

    /// 전용 직렬 체인 안에서만 호출되어 순서와 배타성이 보장된다.
    /// 회전/리사이즈 없이 capturedImage 원본 방향(landscape) 그대로 저장해야 서버가 rgb.mp4 프레임과 동일하게 처리할 수 있다.
    func encode(_ keyframe: Keyframe) {
        let filename = String(format: "frame_%06d.jpg", keyframe.frameNumber)
        let fileURL = imagesDirectory.appendingPathComponent(filename)

        let image = CIImage(cvPixelBuffer: keyframe.pixelBuffer)
        let qualityKey = CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String)
        guard let jpegData = context.jpegRepresentation(of: image, colorSpace: colorSpace, options: [qualityKey: jpegQuality]) else {
            #if DEBUG
            print("KeyframeEncoder: JPEG 인코딩 실패 (frame \(keyframe.frameNumber))")
            #endif
            status = .encodingError
            return
        }

        do {
            try jpegData.write(to: fileURL)
        } catch {
            #if DEBUG
            print("KeyframeEncoder: JPEG 저장 실패 (frame \(keyframe.frameNumber)). \(error.localizedDescription)")
            #endif
            status = .encodingError
            return
        }

        let line = String(
            format: "%06d, %f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.3f\n",
            keyframe.frameNumber,
            keyframe.timestamp,
            keyframe.intrinsics[0][0],
            keyframe.intrinsics[1][1],
            keyframe.intrinsics[2][0],
            keyframe.intrinsics[2][1],
            keyframe.exposureDuration * 1000.0,
            keyframe.exposureOffset,
            keyframe.gyroMagnitude
        )
        do {
            try fileHandle.write(contentsOf: Data(line.utf8))
        } catch {
            #if DEBUG
            print("KeyframeEncoder: CSV 기록 실패 (frame \(keyframe.frameNumber)). \(error.localizedDescription)")
            #endif
            status = .encodingError
        }
    }

    func done() {
        do {
            try fileHandle.close()
        } catch {
            #if DEBUG
            print("KeyframeEncoder: 파일 닫기 실패. \(error.localizedDescription)")
            #endif
            status = .encodingError
        }
    }

    /// capturedImage(YUV biplanar)를 새 CVPixelBuffer로 깊은 복사한다.
    /// 1920x1440 기준 약 4MB memcpy(1ms 수준)로, ARSession 델리게이트 큐에서 동기 호출해도 안전하다.
    static func copyPixelBuffer(_ source: CVPixelBuffer) -> CVPixelBuffer? {
        let width = CVPixelBufferGetWidth(source)
        let height = CVPixelBufferGetHeight(source)
        let format = CVPixelBufferGetPixelFormatType(source)

        var copy: CVPixelBuffer?
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, nil, &copy) == kCVReturnSuccess,
              let destination = copy else { return nil }

        CVPixelBufferLockBaseAddress(source, .readOnly)
        CVPixelBufferLockBaseAddress(destination, [])
        defer {
            CVPixelBufferUnlockBaseAddress(destination, [])
            CVPixelBufferUnlockBaseAddress(source, .readOnly)
        }

        if CVPixelBufferIsPlanar(source) {
            for plane in 0..<CVPixelBufferGetPlaneCount(source) {
                guard let sourceAddress = CVPixelBufferGetBaseAddressOfPlane(source, plane),
                      let destinationAddress = CVPixelBufferGetBaseAddressOfPlane(destination, plane) else { return nil }
                let sourceBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(source, plane)
                let destinationBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(destination, plane)
                let planeHeight = CVPixelBufferGetHeightOfPlane(source, plane)
                if sourceBytesPerRow == destinationBytesPerRow {
                    memcpy(destinationAddress, sourceAddress, sourceBytesPerRow * planeHeight)
                } else {
                    let bytesPerRow = min(sourceBytesPerRow, destinationBytesPerRow)
                    for row in 0..<planeHeight {
                        memcpy(
                            destinationAddress + row * destinationBytesPerRow,
                            sourceAddress + row * sourceBytesPerRow,
                            bytesPerRow
                        )
                    }
                }
            }
        } else {
            guard let sourceAddress = CVPixelBufferGetBaseAddress(source),
                  let destinationAddress = CVPixelBufferGetBaseAddress(destination) else { return nil }
            memcpy(destinationAddress, sourceAddress, CVPixelBufferGetDataSize(source))
        }

        // 컬러리메트리 등 버퍼 attachment를 복사본에도 유지
        CVBufferPropagateAttachments(source, destination)
        return destination
    }
}
