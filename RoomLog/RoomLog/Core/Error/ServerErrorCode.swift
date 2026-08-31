//
//  ServerErrorCode.swift
//  RoomLog
//
//  Created by minkyo on 6/2/26.
//

import Foundation

enum ServerErrorCode: String, Sendable {
    // MARK: - Common
    case commonBadRequest = "COMMON_400"
    case commonUnauthorized = "COMMON_401"
    case commonForbidden = "COMMON_403"
    case commonNotFound = "COMMON_404"
    case commonServerError = "COMMON_500"

    // MARK: - Auth
    case authInvalidCredentials = "AUTH_001"
    case authDuplicateEmail = "AUTH_002"
    case authUserNotFound = "AUTH_005"
    case authInvalidToken = "AUTH_006"

    // MARK: - Room
    case roomNotFound = "ROOM_001"
    case roomAccessDenied = "ROOM_002"

    // MARK: - Scan
    case scanNotFound = "SCAN_001"
    case scanNotCompleted = "SCAN_004"

    // MARK: - Analysis
    case analysisNotFound = "ANALYSIS_001"
    case analysisAlreadyProcessed = "ANALYSIS_002"
    case analysisInvalidScanPair = "ANALYSIS_003"
    case analysisNotCompleted = "ANALYSIS_004"

    // MARK: - Defect
    case defectNotFound = "DEFECT_001"
    case defectAccessDenied = "DEFECT_003"

    // MARK: - Estimate
    case estimateCreateFailed = "ESTIMATE_001"
    case estimateNotFound = "ESTIMATE_002"
    case estimateAccessDenied = "ESTIMATE_003"

    // MARK: - Repair
    case repairNotFound = "REPAIR_001"

    // MARK: - RepairShop
    case repairShopNotAvailable = "REPAIRSHOP_001"
    case repairShopNotFound = "REPAIRSHOP_002"

    // MARK: - Chat
    case chatSessionNotFound = "CHAT_001"
    case chatSessionAccessDenied = "CHAT_002"
    case chatAnswerFailed = "CHAT_003"

    case unknown

    init(rawValue: String) {
        switch rawValue {
        case "COMMON_400": self = .commonBadRequest
        case "COMMON_401": self = .commonUnauthorized
        case "COMMON_403": self = .commonForbidden
        case "COMMON_404": self = .commonNotFound
        case "COMMON_500": self = .commonServerError
        case "AUTH_001": self = .authInvalidCredentials
        case "AUTH_002": self = .authDuplicateEmail
        case "AUTH_005": self = .authUserNotFound
        case "AUTH_006": self = .authInvalidToken
        case "ROOM_001": self = .roomNotFound
        case "ROOM_002": self = .roomAccessDenied
        case "SCAN_001": self = .scanNotFound
        case "SCAN_004": self = .scanNotCompleted
        case "ANALYSIS_001": self = .analysisNotFound
        case "ANALYSIS_002": self = .analysisAlreadyProcessed
        case "ANALYSIS_003": self = .analysisInvalidScanPair
        case "ANALYSIS_004": self = .analysisNotCompleted
        case "DEFECT_001": self = .defectNotFound
        case "DEFECT_003": self = .defectAccessDenied
        case "ESTIMATE_001": self = .estimateCreateFailed
        case "ESTIMATE_002": self = .estimateNotFound
        case "ESTIMATE_003": self = .estimateAccessDenied
        case "REPAIR_001": self = .repairNotFound
        case "REPAIRSHOP_001": self = .repairShopNotAvailable
        case "REPAIRSHOP_002": self = .repairShopNotFound
        case "CHAT_001": self = .chatSessionNotFound
        case "CHAT_002": self = .chatSessionAccessDenied
        case "CHAT_003": self = .chatAnswerFailed
        default: self = .unknown
        }
    }

    var userMessage: String {
        switch self {
        case .commonBadRequest: return "잘못된 요청입니다."
        case .commonUnauthorized: return "인증이 필요합니다."
        case .commonForbidden: return "접근 권한이 없습니다."
        case .commonNotFound: return "요청한 데이터를 찾을 수 없습니다."
        case .commonServerError: return "서버 내부 오류가 발생했습니다."
        case .authInvalidCredentials: return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .authDuplicateEmail: return "이미 가입된 이메일입니다."
        case .authUserNotFound: return "사용자를 찾을 수 없습니다."
        case .authInvalidToken: return "만료되었거나 유효하지 않은 토큰입니다."
        case .roomNotFound: return "존재하지 않는 방입니다."
        case .roomAccessDenied: return "해당 방에 접근 권한이 없습니다."
        case .scanNotFound: return "존재하지 않는 스캔입니다."
        case .scanNotCompleted: return "스캔이 아직 완료되지 않았습니다."
        case .analysisNotFound: return "분석 결과가 존재하지 않습니다."
        case .analysisAlreadyProcessed: return "이미 처리된 분석입니다."
        case .analysisInvalidScanPair: return "선택한 스캔 조합이 올바르지 않거나 비교 가능한 스캔이 부족합니다."
        case .analysisNotCompleted: return "분석이 아직 완료되지 않았습니다."
        case .defectNotFound: return "존재하지 않는 하자 정보입니다."
        case .defectAccessDenied: return "대표 집에 등록된 하자가 아닙니다."
        case .estimateCreateFailed: return "견적 요청 생성에 실패했습니다."
        case .estimateNotFound: return "존재하지 않는 견적 요청입니다."
        case .estimateAccessDenied: return "해당 견적 요청에 접근 권한이 없습니다."
        case .repairNotFound: return "존재하지 않는 수리 내역입니다."
        case .repairShopNotAvailable: return "추천 가능한 수리 업체가 없습니다."
        case .repairShopNotFound: return "업체 정보를 찾을 수 없습니다."
        case .chatSessionNotFound: return "존재하지 않는 대화입니다."
        case .chatSessionAccessDenied: return "해당 대화에 접근 권한이 없습니다."
        case .chatAnswerFailed: return "답변 생성에 실패했습니다. 다시 시도해 주세요."
        case .unknown: return "알 수 없는 오류가 발생했습니다."
        }
    }
}
