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

    init() throws {
        userDefaults = try #require(UserDefaults(suiteName: suiteName))
        sut = ChatbotViewModel(provider: provider, userDefaults: userDefaults)
    }

    deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    private func makeAnswer(_ text: String) -> ChatAnswer {
        ChatAnswer(messageId: 10, answer: text, source: .gpt, suggestedQuestions: nil)
    }

    // MARK: - linkedDefectId

    @Test func 자가수리안내_문구와_첨부하자가_있으면_답변에_linkedDefectId가_붙는다() async throws {
        provider.sendMessageResult = .success(makeAnswer("자세한 방법은 자가 수리 안내 페이지에서 확인해 주세요."))
        await sut.start()
        sut.attachedDefect = sampleDefect

        await sut.send("이 하자 어떻게 고쳐요?")

        let assistant = try #require(sut.messages.last)
        #expect(assistant.role == .assistant)
        #expect(assistant.linkedDefectId == 7)
        #expect(provider.lastSendRequest?.defectId == 7)
    }

    @Test func 첨부하자_없이_문구만_있으면_linkedDefectId는_nil이다() async {
        provider.sendMessageResult = .success(makeAnswer("자가 수리 안내 페이지에서 확인해 주세요."))
        await sut.start()

        await sut.send("벽지 찢어짐은 어떻게 보수하나요?")

        #expect(sut.messages.last?.linkedDefectId == nil)
        #expect(provider.lastSendRequest?.defectId == nil)
    }

    @Test func 첨부하자가_있어도_문구가_없으면_linkedDefectId는_nil이다() async {
        provider.sendMessageResult = .success(makeAnswer("벽지 전용 풀로 부착해 주세요."))
        await sut.start()
        sut.attachedDefect = sampleDefect

        await sut.send("이 하자 어떻게 고쳐요?")

        #expect(sut.messages.last?.linkedDefectId == nil)
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
}
