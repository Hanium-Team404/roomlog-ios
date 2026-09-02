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
        .presentationDetents([.height(320)])
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

    @ViewBuilder
    private var description: some View {
        VStack(spacing: 8) {
            switch phase {
            case .zipping:
                Text("압축 중")
                    .font(.semibold, 20)
                Text("스캔 데이터를 압축하고 있습니다")
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
            case .uploading:
                Text("업로드 중")
                    .font(.semibold, 20)
                Text("스캔 데이터를 서버에 전송하고 있습니다")
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
            case .polling:
                Text("서버 처리 중")
                    .font(.semibold, 20)
                Text("3D 모델을 생성하고 있습니다\n잠시만 기다려주세요")
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .completed:
                Text("스캔 완료")
                    .font(.semibold, 20)
                Text("3D 모델이 준비되었습니다\n스캔 화면에서 미리보기할 수 있습니다")
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .failed(let msg):
                Text("스캔 실패")
                    .font(.semibold, 20)
                Text(msg)
                    .font(.medium, 14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
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
            Button {
                onPreview?(fileURL)
            } label: {
                Text("미리보기")
                    .font(.semibold, 16)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .glassEffect(.regular.interactive().tint(.accent), in: .capsule)
            .padding(.horizontal, 32)
        case .failed:
            // 스와이프로 시트를 내리면 상태가 유지되므로, 포기는 명시적 취소 버튼으로만 가능하다
            VStack(spacing: 12) {
                if let onRetry {
                    Button {
                        onRetry()
                    } label: {
                        Text("다시 시도")
                            .font(.semibold, 16)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .glassEffect(.regular.interactive().tint(.accent), in: .capsule)
                    .padding(.horizontal, 32)
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
