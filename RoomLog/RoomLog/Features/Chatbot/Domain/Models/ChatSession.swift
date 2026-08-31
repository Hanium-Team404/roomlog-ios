//
//  ChatSession.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

struct ChatSession {
    let id: Int
    let greeting: String
    let suggestedQuestions: [ChatSuggestedQuestion]
}

/// 추천 질문. 세션 재진입 시 패널 복원을 위해 로컬 캐싱하므로 Codable 채택.
struct ChatSuggestedQuestion: Hashable, Codable {
    let question: String
    /// 서버 guide 코드. 함께 전송하면 GPT를 거치지 않고 즉답을 받는다.
    let guide: String?
}
