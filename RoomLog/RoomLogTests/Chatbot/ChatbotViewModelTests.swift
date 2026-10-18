//
//  ChatbotViewModelTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/11/26.
//

import Testing
import Foundation
@testable import RoomLog

/// 답변 문구와 첨부 하자 조합에 따라 "자가 수리 안내 보기" 링크(`linkedDefectId`)가 붙는지 검사한다.
/// 세션 저장에 UserDefaults를 쓰므로 테스트마다 고유 suite를 만들고 끝나면 지운다(병렬 실행 대비)
@MainActor
final class ChatbotViewModelTests {

    private let provider = MockChatbotUseCaseProvider()
    private let suiteName = "ChatbotViewModelTests.\(UUID().uuidString)"
    private let userDefaults: UserDefaults
    private let sut: ChatbotViewModel

    private let sampleDefect = ChatSelectableDefect(
        id: 7, type: .peeling, severity: .low, location: "벽면 북서부", roomName: "거실", imageURL: nil
    )

    private let historyJSON = """
    {
      "success": true, "code": 200, "message": "OK",
      "data": {
        "session_id": 42,
        "messages": [
          {
            "message_id": 100, "role": "USER", "defect_id": 178,
            "content": "이 하자의 자가 수리 안내를 보여주세요.", "created_at": "2026-10-11T13:00:00"
          },
          {
            "message_id": 101, "role": "ASSISTANT", "defect_id": 178,
            "content": "자세한 방법은 자가 수리 안내 페이지에서 확인해 주세요.", "created_at": "2026-10-11T13:00:01"
          },
          {
            "message_id": 102, "role": "USER", "defect_id": 178,
            "content": "이 하자에는 어떤 재료가 필요한가요?", "created_at": "2026-10-11T13:01:00"
          },
          {
            "message_id": 103, "role": "ASSISTANT", "defect_id": 178,
            "content": "벽지 전용 풀을 준비해 주세요.", "created_at": "2026-10-11T13:01:01"
          }
        ]
      }
    }
    """

    init() throws {
        userDefaults = try #require(UserDefaults(suiteName: suiteName))
        sut = ChatbotViewModel(provider: provider, userDefaults: userDefaults)
    }

    // deinit은 기본적으로 격리 밖에서 돌아 MainActor 프로퍼티(UserDefaults)에 접근할 수 없다 — 액터 위에서 실행한다
    isolated deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    private func makeAnswer(_ text: String) -> ChatAnswer {
        ChatAnswer(messageId: 10, answer: text, source: .gpt, suggestedQuestions: nil)
    }

    /// "저장된 세션이 있는 상태"를 만든다. 저장소 키를 테스트가 직접 알지 않도록
    /// 임시 ViewModel의 새 세션 시작 경로로 sessionId·추천 질문을 심고, 이후 C03 내역 응답을 준비한다
    private func configureHistory(_ json: String, suggestedQuestions: [ChatSuggestedQuestion] = []) async throws {
        let response = try JSONDecoder().decode(APIResponse<ChatHistoryResponseDTO>.self, from: Data(json.utf8))
        let history = try response.unwrap()
        provider.startSessionResult = .success(
            ChatSession(id: history.sessionId, greeting: "안녕하세요", suggestedQuestions: suggestedQuestions)
        )
        await ChatbotViewModel(provider: provider, userDefaults: userDefaults).start()
        provider.getMessagesResult = .success(history.messages.map { $0.toDomain() })
    }

    // MARK: - linkedDefectId

    @Test func 자가수리안내_문구와_첨부하자가_있으면_답변에_linkedDefectId가_붙는다() async throws {
        provider.sendMessageResult = .success(makeAnswer("자세한 방법은 자가 수리 안내 페이지에서 확인해 주세요."))
        await sut.start()
        sut.attachedDefect = sampleDefect

        await sut.send("이 하자 어떻게 고쳐요?")

        let user = try #require(sut.messages.first { $0.role == .user })
        #expect(user.attachedDefect == sampleDefect)
        #expect(user.defectId == 7)
        let assistant = try #require(sut.messages.last)
        #expect(assistant.role == .assistant)
        #expect(assistant.linkedDefectId == 7)
        #expect(provider.lastSendRequest?.defectId == 7)
    }

    @Test func 첨부하자_없이_문구만_있으면_linkedDefectId는_nil이다() async throws {
        provider.sendMessageResult = .success(makeAnswer("자가 수리 안내 페이지에서 확인해 주세요."))
        await sut.start()

        await sut.send("벽지 찢어짐은 어떻게 보수하나요?")

        let assistant = try #require(sut.messages.last)
        try #require(assistant.role == .assistant)
        #expect(assistant.content == "자가 수리 안내 페이지에서 확인해 주세요.")
        #expect(assistant.linkedDefectId == nil)
        #expect(provider.lastSendRequest?.defectId == nil)
    }

    @Test func 첨부하자가_있어도_문구가_없으면_linkedDefectId는_nil이다() async throws {
        provider.sendMessageResult = .success(makeAnswer("벽지 전용 풀로 부착해 주세요."))
        await sut.start()
        sut.attachedDefect = sampleDefect

        await sut.send("이 하자 어떻게 고쳐요?")

        let assistant = try #require(sut.messages.last)
        try #require(assistant.role == .assistant)
        #expect(assistant.content == "벽지 전용 풀로 부착해 주세요.")
        #expect(assistant.linkedDefectId == nil)
    }

    @Test func 재시도_성공_시_실패했던_요청의_첨부하자로_linkedDefectId가_붙는다() async throws {
        provider.sendMessageResult = .failure(NSError(domain: "test", code: -1))
        await sut.start()
        sut.attachedDefect = sampleDefect
        await sut.send("이 하자 어떻게 고쳐요?")
        try #require(sut.sendFailed)

        provider.sendMessageResult = .success(makeAnswer("자가 수리 안내 페이지에서 확인해 주세요."))
        await sut.retrySend()

        #expect(sut.sendFailed == false)
        #expect(sut.messages.last?.linkedDefectId == 7)
    }

    // MARK: - History

    /// C04 모의 훅은 `start()`가 하자 목록 응답을 기다리며 멈춰 있는 시점에 실행되므로,
    /// 그 안에서 "복원 중" 상태와 전송 차단을 검사한다. continuation이나 별도 Task 없이 구조적으로 끝나 행(hang)이 생길 수 없다
    @Test func 첨부_복원이_끝나기_전에는_일반_메시지와_추천_질문을_전송하지_않는다() async throws {
        let question = ChatSuggestedQuestion(question: "자가 수리 안내를 보여주세요.", guide: "SELF_REPAIR")
        try await configureHistory(historyJSON, suggestedQuestions: [question])
        let history = try provider.getMessagesResult.get()
        provider.onGetSelectableDefects = { [sut, provider] in
            #expect(sut.isLoading)
            #expect(sut.canSend == false)
            #expect(sut.suggestedQuestions.isEmpty)
            await sut.sendSuggested(question)
            await sut.send("이 하자는 어떻게 고치나요?")
            #expect(provider.lastSendRequest == nil)
            #expect(sut.messages.isEmpty)
        }
        defer { provider.onGetSelectableDefects = nil }

        await sut.start()

        #expect(sut.messages == history)
        #expect(sut.suggestedQuestions == [question])
        #expect(provider.getSelectableDefectsCallCount == 1)
        #expect(sut.isLoading == false)
        #expect(sut.loadFailed == false)
        #expect(sut.canSend)
    }

    @Test func C03_복원시_답변_링크와_반복된_사용자_첨부를_하자목록_한번_조회로_복원한다() async throws {
        try await configureHistory(historyJSON)
        let defect = ChatSelectableDefect(
            id: 178, type: .peeling, severity: .low, location: "벽면 북서부", roomName: "거실", imageURL: nil
        )
        provider.getSelectableDefectsResult = .success([defect])

        await sut.start()

        try #require(sut.messages.count == 4)
        #expect(sut.messages.map(\.defectId) == [178, 178, 178, 178])
        #expect(sut.messages.map(\.role) == [.user, .assistant, .user, .assistant])
        #expect(sut.messages.map(\.linkedDefectId) == [nil, 178, nil, nil])
        #expect(sut.messages[0].attachedDefect == defect)
        #expect(sut.messages[2].attachedDefect == defect)
        #expect(sut.messages[1].attachedDefect == nil)
        #expect(sut.messages[3].attachedDefect == nil)
        #expect(provider.getSelectableDefectsCallCount == 1)
        #expect(sut.loadFailed == false)
        #expect(sut.canSend)
    }

    @Test(arguments: ["", "\"defect_id\": null,"])
    func C03의_defect_id가_없거나_null이어도_대화를_복원한다(defectIdField: String) async throws {
        let json = """
        {
          "success": true, "code": 200, "message": "OK",
          "data": {
            "session_id": 42,
            "messages": [
              {
                "message_id": 100, "role": "USER", \(defectIdField)
                "content": "자가 수리 안내를 보여주세요.", "created_at": null
              },
              {
                "message_id": 101, "role": "ASSISTANT", \(defectIdField)
                "content": "자가 수리 안내 페이지에서 확인해 주세요.", "created_at": null
              }
            ]
          }
        }
        """
        try await configureHistory(json)

        await sut.start()

        try #require(sut.messages.count == 2)
        #expect(sut.messages.allSatisfy { $0.defectId == nil && $0.linkedDefectId == nil && $0.attachedDefect == nil })
        #expect(provider.getSelectableDefectsCallCount == 0)
        #expect(sut.loadFailed == false)
        #expect(sut.canSend)
    }

    @Test func 첨부_복원용_하자목록_조회에_실패해도_대화와_답변_링크를_보존한다() async throws {
        try await configureHistory(historyJSON)
        let history = try provider.getMessagesResult.get()
        provider.getSelectableDefectsResult = .failure(NSError(domain: "test", code: -1))

        await sut.start()

        #expect(sut.messages == history)
        #expect(sut.messages.allSatisfy { $0.attachedDefect == nil })
        #expect(sut.messages.map(\.linkedDefectId) == [nil, 178, nil, nil])
        #expect(provider.getSelectableDefectsCallCount == 1)
        #expect(sut.loadFailed == false)
        #expect(sut.canSend)
    }

    @Test func 하자목록에_없는_과거_첨부는_nil로_두고_대화와_답변_링크를_보존한다() async throws {
        try await configureHistory(historyJSON)
        let history = try provider.getMessagesResult.get()
        provider.getSelectableDefectsResult = .success([sampleDefect])

        await sut.start()

        #expect(sut.messages == history)
        #expect(sut.messages.allSatisfy { $0.attachedDefect == nil })
        #expect(sut.messages.map(\.linkedDefectId) == [nil, 178, nil, nil])
        #expect(provider.getSelectableDefectsCallCount == 1)
        #expect(sut.loadFailed == false)
        #expect(sut.canSend)
    }
}
