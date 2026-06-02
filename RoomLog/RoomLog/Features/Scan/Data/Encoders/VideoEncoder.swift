//
//  VideoEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation
@preconcurrency import AVFoundation
import ARKit

struct VideoEncoderInput {
    let buffer: CVPixelBuffer
    let time: TimeInterval
}

final class VideoEncoder: @unchecked Sendable {
    enum EncodingStatus { case allGood, error }

    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var videoAdapter: AVAssetWriterInputPixelBufferAdaptor?
    private let timeScale = CMTimeScale(600)
    private var firstFrameTime: TimeInterval?

    let width: CGFloat
    let height: CGFloat
    let filePath: URL
    var status: EncodingStatus = .allGood

    init(file: URL, width: CGFloat, height: CGFloat) {
        self.filePath = file
        self.width = width
        self.height = height
        initializeFile()
    }

    func finishEncoding() async {
        await doneRecording()
    }

    func add(frame: VideoEncoderInput) async {
        var spinCount = 0
        while !(videoWriterInput?.isReadyForMoreMediaData ?? false) {
            if videoWriter?.status == .failed || spinCount > 500 {
                status = .error
                return
            }
            spinCount += 1
            try? await Task.sleep(for: .milliseconds(10))
        }
        encode(frame: frame)
    }

    // MARK: - Private

    private func initializeFile() {
        do {
            let writer = try AVAssetWriter(outputURL: filePath, fileType: .mp4)
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            input.expectsMediaDataInRealTime = true
            input.mediaTimeScale = timeScale
            input.performsMultiPassEncodingIfSupported = false

            let adapter = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: nil
            )

            guard writer.canAdd(input) else {
                status = .error
                return
            }
            writer.add(input)
            videoWriterInput = input
            videoAdapter = adapter
            videoWriter = writer
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)
        } catch {
            print("VideoEncoder: AVAssetWriter 생성 실패. \(error.localizedDescription)")
            status = .error
        }
    }

    private func encode(frame: VideoEncoderInput) {
        let anchor = firstFrameTime ?? frame.time
        if firstFrameTime == nil { firstFrameTime = frame.time }
        let time = CMTime(seconds: frame.time - anchor, preferredTimescale: timeScale)
        if videoAdapter?.append(frame.buffer, withPresentationTime: time) == false {
            print("VideoEncoder: pixel buffer append 실패.")
            status = .error
        }
    }

    private func doneRecording() async {
        guard let writer = videoWriter else { return }
        guard writer.status != .failed else {
            print("VideoEncoder: 인코딩 중 오류 발생.")
            status = .error
            return
        }
        videoWriterInput?.markAsFinished()
        await writer.finishWriting()
        if writer.status == .failed { status = .error }
        videoWriter = nil
        videoWriterInput = nil
        videoAdapter = nil
    }
}
