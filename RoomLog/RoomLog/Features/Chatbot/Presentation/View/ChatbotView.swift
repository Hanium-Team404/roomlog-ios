//
//  ChatbotView.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import SwiftUI

struct ChatbotView: View {
    @State private var viewModel: ChatbotViewModel

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
                ChatMessageList(
                    messages: viewModel.messages,
                    showsDefectSelectCard: viewModel.isConversationEmpty,
                    isTyping: viewModel.isTyping,
                    sendFailed: viewModel.sendFailed,
                    onSelectDefect: { viewModel.showDefectSheet = true },
                    onRetrySend: { Task { await viewModel.retrySend() } }
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !viewModel.loadFailed {
                ChatBottomBar(
                    suggestedQuestions: viewModel.suggestedQuestions,
                    isPanelExpanded: $viewModel.isPanelExpanded,
                    attachedDefect: viewModel.attachedDefect,
                    isSending: viewModel.isTyping,
                    canSend: viewModel.canSend,
                    onSelectQuestion: { question in
                        Task { await viewModel.sendSuggested(question) }
                    },
                    onRemoveAttachment: { viewModel.attachedDefect = nil },
                    onAttach: { viewModel.showDefectSheet = true },
                    onSend: { text in
                        Task { await viewModel.send(text) }
                    }
                )
            }
        }
        .navigationTitle("루미")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("새 채팅", systemImage: "square.and.pencil") {
                    Task { await viewModel.startNewChat() }
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
}

#Preview {
    NavigationStack {
        ChatbotView(
            provider: ChatbotUseCaseProviderImpl(chatRepository: MockChatRepository())
        )
    }
}
