//
//  MockChatRepository.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

/// Preview 및 서버 미연동 상태 테스트용 Mock
final class MockChatRepository: ChatRepositoryProtocol {
    func startSession() async throws -> ChatSession {
        ChatSession(
            id: 1,
            greeting: "안녕하세요! 하자 해결을 도와드리는 RoomLog 챗봇 루미입니다 ☺️",
            suggestedQuestions: [
                ChatSuggestedQuestion(question: "3D 스캔은 어떻게 하나요?", guide: "GUIDE_SCAN"),
                ChatSuggestedQuestion(question: "하자 분석은 어떻게 요청하나요?", guide: "GUIDE_ANALYSIS"),
                ChatSuggestedQuestion(question: "내 방 비교 기능이 뭔가요?", guide: "GUIDE_COMPARE"),
                ChatSuggestedQuestion(question: "수리 업체 추천을 받고 싶어요", guide: "GUIDE_ESTIMATE")
            ]
        )
    }

    func sendMessage(sessionId: Int, message: String, guide: String?, defectId: Int?) async throws -> ChatAnswer {
        try? await Task.sleep(for: .seconds(1))
        return ChatAnswer(
            messageId: 100,
            answer: "3D 스캔은 홈 화면에서 집을 선택한 뒤 스캔 버튼을 눌러 시작할 수 있어요. 방 전체를 천천히 비추면 자동으로 공간이 기록됩니다.",
            source: guide != nil ? .guide : .gpt,
            suggestedQuestions: nil
        )
    }

    func getMessages(sessionId: Int) async throws -> [ChatMessage] {
        [
            ChatMessage(role: .assistant, content: "안녕하세요! 하자 해결을 도와드리는 RoomLog 챗봇 루미입니다 ☺️"),
            ChatMessage(role: .user, content: "벽지 찢어짐은 어떻게 보수하나요?"),
            ChatMessage(role: .assistant, content: "찢어진 부분 주변을 깨끗하게 청소한 뒤, 벽지 전용 풀로 부착해 주세요.")
        ]
    }

    func getMainHouseDefects() async throws -> [ChatSelectableDefect] {
        [
            ChatSelectableDefect(id: 1, type: .peeling, severity: .low, location: "벽면 북서부", roomName: "거실", imageURL: nil),
            ChatSelectableDefect(id: 2, type: .crack, severity: .medium, location: "중앙부", roomName: "거실", imageURL: nil),
            ChatSelectableDefect(id: 3, type: .stain, severity: .high, location: "천장", roomName: "침실", imageURL: nil)
        ]
    }
}
