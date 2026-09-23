//
//  ScanProcessingState.swift
//  RoomLog
//
//  Created by Doyeon Kim on 9/22/26.
//

import Foundation

// MARK: - 스캔 파이프라인 상태 타입

extension ScanProcessingManager {

    enum ProcessingPhase: Equatable {
        case zipping
        case uploading
        case polling
        case completed(fileURL: URL)
        case failed(ScanFailure)
    }

    /// 실패 표시 문구와 재개 방법을 한 단위로 보관한다.
    /// `retrySource`가 nil이면 재시도해도 결과가 같은 실패(디코딩·비즈니스 거부 등)라 재시도 불가.
    /// 파이프라인 단계가 Error로 던지면 디스패처(`start`)가 한 곳에서 `.failed`로 기록한다.
    struct ScanFailure: Error, Equatable {
        let userMessage: String
        let retrySource: RetrySource?
    }

    struct ActiveScan: Equatable {
        let scanId: Int
        let houseId: Int
        let phase: ProcessingPhase
    }

    /// 폴링 간격·시도 횟수 설정. 테스트에서 짧은 간격을 주입할 수 있다.
    /// init의 기본 인자(`PollConfig()`)는 nonisolated 컨텍스트에서 평가되므로 격리에서 제외한다.
    nonisolated struct PollConfig {
        var maxAttempts = 60
        var interval: Duration = .seconds(7)
        var maxConsecutiveErrors = 3
    }

    /// 실패 지점에 따른 재시도 방식.
    /// `ScanFailure`(Error)의 Equatable 합성이 nonisolated로 추론되므로 비교되는 이 타입도 격리에서 제외한다.
    nonisolated enum RetrySource: Equatable {
        /// 업로드 실패: 보존해둔 zip으로 재업로드
        case upload(zipURL: URL)
        /// 상태 조회 실패: 서버 상태를 모르므로 재폴링부터 다시 수행
        case polling(scanId: Int)
        /// 프리뷰 다운로드 실패: 서버 처리는 이미 COMPLETED이므로 폴링 없이 재다운로드만 수행
        case download(scanId: Int)
    }

    /// 파이프라인 진입점 — 시작·재시도·복원 경로가 모두 이 값으로 수렴한다.
    /// 단계 본문은 각자의 함수로 유지하고, "어디서부터 실행할지"만 데이터로 명명한다.
    enum PipelineEntry {
        case full(encoder: DatasetEncoder)
        case upload(zipURL: URL)
        case polling(scanId: Int)
        case download(scanId: Int)

        var scanId: Int {
            switch self {
            case .full, .upload: 0
            case .polling(let scanId), .download(let scanId): scanId
            }
        }

        /// 진입 시 표시할 단계. download는 폴링을 생략하지만 UI 표기는 polling을 공유한다
        var initialPhase: ProcessingPhase {
            switch self {
            case .full: .zipping
            case .upload: .uploading
            case .polling, .download: .polling
            }
        }
    }
}

extension ScanProcessingManager.RetrySource {
    /// 재시도 소스를 파이프라인 진입점으로 변환
    var entry: ScanProcessingManager.PipelineEntry {
        switch self {
        case .upload(let zipURL): .upload(zipURL: zipURL)
        case .polling(let scanId): .polling(scanId: scanId)
        case .download(let scanId): .download(scanId: scanId)
        }
    }
}
