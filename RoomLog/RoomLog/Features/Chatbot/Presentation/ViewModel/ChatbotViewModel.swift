//
//  ChatbotViewModel.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

@Observable
final class ChatbotViewModel {
    // MARK: - State
    private(set) var messages: [ChatMessage] = []
    private(set) var suggestedQuestions: [ChatSuggestedQuestion] = []
    var isPanelExpanded = true
    /// 답변 대기 중 (타이핑 인디케이터 표시)
    private(set) var isTyping = false
    /// 마지막 전송 실패 여부 (재시도 버튼 표시)
    private(set) var sendFailed = false
    private(set) var isLoading = false
    private(set) var loadFailed = false

    // MARK: - 하자 첨부
    var showDefectSheet = false
    var attachedDefect: ChatSelectableDefect?
    private(set) var selectableDefects: [ChatSelectableDefect] = []
    private(set) var isDefectListLoading = false
    private(set) var defectListLoadFailed = false

    static let maxMessageLength = 300

    // MARK: - Dependency
    private let provider: ChatbotUseCaseProvider
    private let userDefaults: UserDefaults

    private var sessionId: Int?
    private var lastFailedRequest: (message: String, guide: String?, defectId: Int?)?

    private enum StorageKey {
        static let sessionId = "chatbot.sessionId"
        static let suggestedQuestions = "chatbot.suggestedQuestions"
        static let greeting = "chatbot.greeting"
    }

    private static let defaultGreeting = "안녕하세요! 하자 해결을 도와드리는 RoomLog 챗봇 루미입니다 ☺️"

    init(provider: ChatbotUseCaseProvider, userDefaults: UserDefaults = .standard) {
        self.provider = provider
        self.userDefaults = userDefaults
    }

    /// 사용자가 아직 메시지를 보내지 않은 상태 (하자 선택 카드 노출 조건)
    var isConversationEmpty: Bool {
        !messages.contains { $0.role == .user }
    }

    /// 세션이 준비된 상태에서만 전송 허용 (세션 없이 전송 시 입력만 유실되는 것 방지)
    var canSend: Bool {
        sessionId != nil && !isLoading && !loadFailed
    }

    // MARK: - Session

    /// 진입 시 호출. 저장된 세션이 있으면 내역을 복원하고, 없거나 유효하지 않으면 새 세션을 시작한다.
    func start() async {
        guard messages.isEmpty, !isLoading else { return }
        isLoading = true
        loadFailed = false
        defer { isLoading = false }

        if let stored = storedSessionId {
            do {
                let history = try await provider.makeGetChatMessagesUseCase().execute(sessionId: stored)
                sessionId = stored
                suggestedQuestions = cachedSuggestedQuestions
                if history.isEmpty {
                    // 서버 내역에는 C01 greeting이 포함되지 않으므로 캐싱해둔 greeting으로 첫 화면 복원
                    messages = [ChatMessage(role: .assistant, content: cachedGreeting)]
                    isPanelExpanded = true
                } else {
                    messages = history
                    isPanelExpanded = false
                }
                return
            } catch {
                // CHAT_001(없는 대화)/CHAT_002(권한 없음)일 때만 세션을 버리고 새로 시작.
                // 일시적인 네트워크/디코딩 오류로 기존 대화가 유실되지 않도록 그 외에는 재시도 유도.
                let errorCode = (error as? RepositoryError)?.serverErrorCode
                guard errorCode == .chatSessionNotFound || errorCode == .chatSessionAccessDenied else {
                    loadFailed = true
                    return
                }
                clearStoredSession()
            }
        }
        await startNewSession()
    }

    func retryStart() async {
        loadFailed = false
        await start()
    }

    /// 기존 세션을 버리고 새 대화를 시작한다.
    func startNewChat() async {
        guard !isTyping, !isLoading else { return }
        clearStoredSession()
        sessionId = nil
        messages = []
        lastFailedRequest = nil
        sendFailed = false
        attachedDefect = nil
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        await startNewSession()
    }

    private func startNewSession() async {
        do {
            let session = try await provider.makeStartChatSessionUseCase().execute()
            sessionId = session.id
            messages = [ChatMessage(role: .assistant, content: session.greeting)]
            suggestedQuestions = session.suggestedQuestions
            isPanelExpanded = true
            userDefaults.set(session.id, forKey: StorageKey.sessionId)
            userDefaults.set(session.greeting, forKey: StorageKey.greeting)
            cache(suggestedQuestions: session.suggestedQuestions)
        } catch {
            loadFailed = true
        }
    }

    // MARK: - Send

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isTyping, sessionId != nil else { return }
        let message = String(trimmed.prefix(Self.maxMessageLength))
        let defect = attachedDefect
        attachedDefect = nil
        messages.append(ChatMessage(role: .user, content: message, attachedDefect: defect))
        isPanelExpanded = false
        await requestAnswer(message: message, guide: nil, defectId: defect?.id)
    }

    func sendSuggested(_ question: ChatSuggestedQuestion) async {
        guard !isTyping, sessionId != nil else { return }
        messages.append(ChatMessage(role: .user, content: question.question))
        isPanelExpanded = false
        await requestAnswer(message: question.question, guide: question.guide, defectId: nil)
    }

    /// 전송 실패 시 재시도. 유저 말풍선은 이미 추가되어 있으므로 요청만 다시 보낸다.
    func retrySend() async {
        guard let request = lastFailedRequest, !isTyping else { return }
        await requestAnswer(message: request.message, guide: request.guide, defectId: request.defectId)
    }

    private func requestAnswer(message: String, guide: String?, defectId: Int?) async {
        guard let sessionId else { return }
        isTyping = true
        sendFailed = false
        defer { isTyping = false }
        do {
            let answer = try await provider.makeSendChatMessageUseCase().execute(
                sessionId: sessionId,
                message: message,
                guide: guide,
                defectId: defectId
            )
            messages.append(ChatMessage(role: .assistant, content: answer.answer))
            lastFailedRequest = nil
            // FALLBACK 답변일 때만 새 추천 질문이 내려온다 → 패널 내용 갱신
            if answer.source == .fallback, let fresh = answer.suggestedQuestions, !fresh.isEmpty {
                suggestedQuestions = fresh
                cache(suggestedQuestions: fresh)
            }
        } catch {
            let errorCode = (error as? RepositoryError)?.serverErrorCode
            if errorCode == .chatSessionNotFound || errorCode == .chatSessionAccessDenied {
                // 세션이 무효화됨 → 저장된 세션을 버리고 새 대화로 시작
                clearStoredSession()
                self.sessionId = nil
                messages = []
                await startNewSession()
                return
            }
            lastFailedRequest = (message, guide, defectId)
            sendFailed = true
        }
    }

    // MARK: - 하자 선택

    func loadDefects() async {
        isDefectListLoading = true
        defectListLoadFailed = false
        defer { isDefectListLoading = false }
        do {
            selectableDefects = try await provider.makeGetChatSelectableDefectsUseCase().execute()
        } catch {
            defectListLoadFailed = true
        }
    }

    func attach(_ defect: ChatSelectableDefect) {
        attachedDefect = defect
        showDefectSheet = false
    }

    // MARK: - Storage

    private var storedSessionId: Int? {
        let value = userDefaults.integer(forKey: StorageKey.sessionId)
        return value == 0 ? nil : value
    }

    private func clearStoredSession() {
        userDefaults.removeObject(forKey: StorageKey.sessionId)
        userDefaults.removeObject(forKey: StorageKey.suggestedQuestions)
        userDefaults.removeObject(forKey: StorageKey.greeting)
    }

    private var cachedGreeting: String {
        userDefaults.string(forKey: StorageKey.greeting) ?? Self.defaultGreeting
    }

    private var cachedSuggestedQuestions: [ChatSuggestedQuestion] {
        guard let data = userDefaults.data(forKey: StorageKey.suggestedQuestions) else { return [] }
        return (try? JSONDecoder().decode([ChatSuggestedQuestion].self, from: data)) ?? []
    }

    private func cache(suggestedQuestions: [ChatSuggestedQuestion]) {
        guard let data = try? JSONEncoder().encode(suggestedQuestions) else { return }
        userDefaults.set(data, forKey: StorageKey.suggestedQuestions)
    }
}
