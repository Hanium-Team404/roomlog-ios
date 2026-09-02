//
//  VideoEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//
//  Based on Stray Scanner (https://github.com/strayrobots/scanner)
//  Copyright (c) 2021 Stray Robots — MIT License
//

import Foundation
@preconcurrency import AVFoundation
import ARKit

nonisolated struct VideoEncoderInput {
    let buffer: CVPixelBuffer
    let time: TimeInterval
}

/// AVAssetWriter 기반 RGB 비디오 인코더.
/// DatasetEncoder의 직렬 인코딩 체인에서만 접근된다 — 체인의 각 Task가 이전 Task의 완료를
/// await하므로 모든 상태 접근이 순차 실행됨이 보장된다. 이 직렬 접근 불변식이 @unchecked Sendable의 근거다.
nonisolated final class VideoEncoder: @unchecked Sendable {
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
            #if DEBUG
            print("VideoEncoder: AVAssetWriter 생성 실패. \(error.localizedDescription)")
            #endif
            status = .error
        }
    }

    private func encode(frame: VideoEncoderInput) {
        let anchor = firstFrameTime ?? frame.time
        if firstFrameTime == nil { firstFrameTime = frame.time }
        let time = CMTime(seconds: frame.time - anchor, preferredTimescale: timeScale)
        if videoAdapter?.append(frame.buffer, withPresentationTime: time) == false {
            #if DEBUG
            print("VideoEncoder: pixel buffer append 실패.")
            #endif
            status = .error
        }
    }

    private func doneRecording() async {
        guard let writer = videoWriter else { return }
        guard writer.status != .failed else {
            #if DEBUG
            print("VideoEncoder: 인코딩 중 오류 발생.")
            #endif
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
