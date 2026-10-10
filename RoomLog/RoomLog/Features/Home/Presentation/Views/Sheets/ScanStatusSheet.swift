//
//  ScanStatusSheet.swift
//  RoomLog
//
//  Created by 김도연 on 5/13/26.
//

import SwiftUI

struct ScanStatusSheet: View {

    let phase: ScanProcessingManager.ProcessingPhase
    var onPreview: ((URL) -> Void)?
    var onCancel: (() -> Void)?
    var onRetry: (() -> Void)?

    @State private var showCancelAlert: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                icon
                description
                action
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("스캔 상태")
            .navigationBarTitleDisplayMode(.inline)
            .alert("스캔 취소", isPresented: $showCancelAlert) {
                Button("계속 진행", role: .cancel) {}
                Button("취소하기", role: .destructive) {
                    onCancel?()
                }
            } message: {
                Text("진행 중인 스캔을 취소하시겠어요?\n스캔 데이터가 삭제됩니다.")
            }
        }
        .presentationDetents([.height(360)])
    }

    // MARK: - Icon

    @ViewBuilder
    private var icon: some View {
        switch phase {
        case .zipping, .uploading, .polling:
            ProgressView()
                .scaleEffect(1.5)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
        }
    }

    // MARK: - Description

    private var description: some View {
        VStack(spacing: 8) {
            Text(phase.title)
                .font(.semibold, 20)
            Text(detail)
                .font(.medium, 14)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    /// 단계 설명에 시트에서만 덧붙이는 안내 줄을 더한다 (Live Activity는 첫 줄만 쓴다)
    private var detail: String {
        switch phase {
        case .polling: "\(phase.message)\n잠시만 기다려주세요"
        case .completed: "\(phase.message)\n아래 미리보기 버튼으로 확인할 수 있습니다"
        case .zipping, .uploading, .failed: phase.message
        }
    }

    // MARK: - Action

    @ViewBuilder
    private var action: some View {
        switch phase {
        case .zipping, .uploading, .polling:
            Button {
                showCancelAlert = true
            } label: {
                Text("취소하기")
                    .font(.semibold, 16)
                    .foregroundStyle(.red)
            }
        case .completed(let fileURL):
            BottomCTAButton {
                onPreview?(fileURL)
            } label: {
                Text("미리보기")
                    .font(.semibold, 16)
            }
        case .failed:
            // 스와이프로 시트를 내리면 상태가 유지되므로, 포기는 명시적 취소 버튼으로만 가능하다
            VStack(spacing: 12) {
                if let onRetry {
                    BottomCTAButton {
                        onRetry()
                    } label: {
                        Text("다시 시도")
                            .font(.semibold, 16)
                    }
                }
                Button {
                    showCancelAlert = true
                } label: {
                    Text("스캔 취소하기")
                        .font(.semibold, 16)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
