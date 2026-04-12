//
//  VideoEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation
import AVFoundation
import ARKit

struct VideoEncoderInput {
    let buffer: CVPixelBuffer
    let time: TimeInterval
}

final class VideoEncoder {
    enum EncodingStatus { case allGood, error }

    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var videoAdapter: AVAssetWriterInputPixelBufferAdaptor?
    private let timeScale = CMTimeScale(60)
    private var previousFrame: Int = -1

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

    func add(frame: VideoEncoderInput, currentFrame: Int) {
        previousFrame = currentFrame
        var spinCount = 0
        while !(videoWriterInput?.isReadyForMoreMediaData ?? false) {
            if videoWriter?.status == .failed || spinCount > 500 {
                status = .error
                return
            }
            spinCount += 1
            Thread.sleep(until: Date() + 0.01)
        }
        encode(frame: frame, frameNumber: currentFrame)
    }

    // MARK: - Private

    private func initializeFile() {
        do {
            videoWriter = try AVAssetWriter(outputURL: filePath, fileType: .mp4)
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            input.expectsMediaDataInRealTime = true
            input.mediaTimeScale = timeScale
            input.performsMultiPassEncodingIfSupported = false

            videoAdapter = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: nil
            )

            if videoWriter!.canAdd(input) {
                videoWriter!.add(input)
                videoWriterInput = input
                videoWriter!.startWriting()
                videoWriter!.startSession(atSourceTime: .zero)
            }
        } catch {
            print("VideoEncoder: AVAssetWriter 생성 실패. \(error.localizedDescription)")
        }
    }

    private func encode(frame: VideoEncoderInput, frameNumber: Int) {
        let time = CMTime(value: Int64(frameNumber), timescale: timeScale)
        if videoAdapter?.append(frame.buffer, withPresentationTime: time) == false {
            print("VideoEncoder: pixel buffer append 실패.")
            status = .error
        }
    }

    private func doneRecording() async {
        guard videoWriter?.status != .failed else {
            print("VideoEncoder: 인코딩 중 오류 발생.")
            status = .error
            return
        }
        videoWriterInput?.markAsFinished()
        await withCheckedContinuation { continuation in
            videoWriter?.finishWriting { [weak self] in
                if self?.videoWriter?.status == .failed { self?.status = .error }
                self?.videoWriter = nil
                self?.videoWriterInput = nil
                self?.videoAdapter = nil
                continuation.resume()
            }
        }
    }
}
