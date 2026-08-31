//
//  ChatbotView.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

struct ChatbotView: View {
    @State private var viewModel: ChatbotViewModel
    @State private var inputText = ""

    init(provider: ChatbotUseCaseProvider) {
        self._viewModel = .init(wrappedValue: ChatbotViewModel(provider: provider))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.loadFailed {
                loadFailedView
            } else {
                messageList
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomArea
        }
        .navigationTitle("루미")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.startNewChat() }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(viewModel.isTyping || viewModel.isLoading)
            }
        }
        .task {
            await viewModel.start()
        }
        .sheet(isPresented: $viewModel.showDefectSheet) {
            DefectSelectSheet(viewModel: viewModel)
        }
    }

    // MARK: - 대화 영역

    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.messages) { message in
                    ChatMessageBubble(message: message)
                }

                // 첫 진입(유저 메시지 없음) 시 하자 선택 카드 노출
                if viewModel.isConversationEmpty {
                    DefectSelectCard {
                        viewModel.showDefectSheet = true
                    }
                }

                if viewModel.isTyping {
                    ChatTypingIndicator()
                }

                if viewModel.sendFailed {
                    sendFailedRow
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeInOut(duration: 0.2), value: viewModel.messages)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isTyping)
    }

    private var sendFailedRow: some View {
        HStack(spacing: 8) {
            Text("답변을 받지 못했어요")
                .font(.medium, 13)
                .foregroundStyle(.secondary)
            Button {
                Task { await viewModel.retrySend() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("다시 시도")
                        .font(.semibold, 13)
                }
                .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var loadFailedView: some View {
        VStack(spacing: 12) {
            Text("대화를 시작하지 못했어요")
                .font(.medium, 15)
                .foregroundStyle(.secondary)
            Button("다시 시도") {
                Task { await viewModel.retryStart() }
            }
            .font(.semibold, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 하단 영역 (첨부 칩 + 추천 질문 패널 + 입력 바)

    private var bottomArea: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(spacing: 10) {
                if !viewModel.suggestedQuestions.isEmpty && !viewModel.loadFailed {
                    SuggestedQuestionsPanel(
                        questions: viewModel.suggestedQuestions,
                        isExpanded: $viewModel.isPanelExpanded
                    ) { question in
                        Task { await viewModel.sendSuggested(question) }
                    }
                }

                ChatInputBar(
                    text: $inputText,
                    isSending: viewModel.isTyping,
                    attachedDefect: viewModel.attachedDefect,
                    onRemoveAttachment: { viewModel.attachedDefect = nil },
                    onAttach: { viewModel.showDefectSheet = true },
                    onSend: sendCurrentInput
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .animation(.snappy, value: viewModel.isPanelExpanded)
        .animation(.snappy, value: viewModel.attachedDefect)
    }

    private func sendCurrentInput() {
        let text = inputText
        inputText = ""
        Task { await viewModel.send(text) }
    }
}

#Preview {
    NavigationStack {
        ChatbotView(
            provider: ChatbotUseCaseProviderImpl(chatRepository: MockChatRepository())
        )
    }
}
