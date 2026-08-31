//
//  ChatMessage.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

struct ChatMessage: Identifiable, Hashable {
    enum Role: Hashable {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let content: String
    /// 함께 전송한 하자 (유저 메시지에만 존재, 말풍선에 첨부 표시용)
    var attachedDefect: ChatSelectableDefect? = nil
}

struct ChatAnswer {
    let messageId: Int
    let answer: String
    let source: ChatAnswerSource
    /// source가 FALLBACK일 때만 서버가 내려주는 새 추천 질문
    let suggestedQuestions: [ChatSuggestedQuestion]?
}

enum ChatAnswerSource {
    case guide, cache, gpt, fallback, unknown

    init(rawString: String) {
        switch rawString.uppercased() {
        case "GUIDE": self = .guide
        case "CACHE": self = .cache
        case "GPT": self = .gpt
        case "FALLBACK": self = .fallback
        default: self = .unknown
        }
    }
}
