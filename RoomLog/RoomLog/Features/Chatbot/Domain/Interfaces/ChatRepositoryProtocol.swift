//
//  ChatRepositoryProtocol.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

protocol ChatRepositoryProtocol {
    /// C01 대화 시작
    func startSession() async throws -> ChatSession
    /// C02 메시지 전송
    func sendMessage(sessionId: Int, message: String, guide: String?, defectId: Int?) async throws -> ChatAnswer
    /// C03 대화 내역 조회
    func getMessages(sessionId: Int) async throws -> [ChatMessage]
    /// C04 대표 집에 등록된 하자 목록 조회 (최신순)
    func getMainHouseDefects() async throws -> [ChatSelectableDefect]
}
