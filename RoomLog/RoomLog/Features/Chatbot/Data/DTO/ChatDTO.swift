//
//  ChatDTO.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

// MARK: - C01 대화 시작

struct ChatSessionResponseDTO: Codable {
    let sessionId: Int
    let greeting: String
    let suggestedQuestions: [SuggestedQuestionDTO]?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case greeting
        case suggestedQuestions = "suggested_questions"
    }

    func toDomain() -> ChatSession {
        ChatSession(
            id: sessionId,
            greeting: greeting,
            suggestedQuestions: (suggestedQuestions ?? []).map { $0.toDomain() }
        )
    }
}

struct SuggestedQuestionDTO: Codable {
    let question: String
    let guide: String?

    func toDomain() -> ChatSuggestedQuestion {
        ChatSuggestedQuestion(question: question, guide: guide)
    }
}

// MARK: - C02 메시지 전송

struct ChatAnswerResponseDTO: Codable {
    let messageId: Int
    let answer: String
    let source: String?
    let suggestedQuestions: [SuggestedQuestionDTO]?

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case answer
        case source
        case suggestedQuestions = "suggested_questions"
    }

    func toDomain() -> ChatAnswer {
        ChatAnswer(
            messageId: messageId,
            answer: answer,
            source: ChatAnswerSource(rawString: source ?? ""),
            suggestedQuestions: suggestedQuestions?.map { $0.toDomain() }
        )
    }
}

// MARK: - C04 대표 집 하자 목록 조회

struct MainHouseDefectsResponseDTO: Codable {
    let defectCount: Int
    let defects: [MainHouseDefectItemDTO]

    enum CodingKeys: String, CodingKey {
        case defectCount = "defect_count"
        case defects
    }
}

struct MainHouseDefectItemDTO: Codable {
    let defectId: Int
    let type: String
    let severity: String
    let location: String
    let roomId: Int?
    let roomName: String?
    let imageUrl: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case defectId = "defect_id"
        case type
        case severity
        case location
        case roomId = "room_id"
        case roomName = "room_name"
        case imageUrl = "image_url"
        case createdAt = "created_at"
    }

    func toDomain() -> ChatSelectableDefect {
        ChatSelectableDefect(
            id: defectId,
            type: DefectType(rawString: type),
            severity: Severity(rawString: severity),
            location: location,
            roomName: roomName ?? "",
            imageURL: imageUrl
        )
    }
}

// MARK: - C03 대화 내역 조회

struct ChatHistoryResponseDTO: Codable {
    let sessionId: Int
    let messages: [ChatHistoryMessageDTO]

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case messages
    }
}

struct ChatHistoryMessageDTO: Codable {
    let messageId: Int
    let role: String
    let content: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case role
        case content
        case createdAt = "created_at"
    }

    func toDomain() -> ChatMessage {
        ChatMessage(
            role: role.uppercased() == "USER" ? .user : .assistant,
            content: content
        )
    }
}
