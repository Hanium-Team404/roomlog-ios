//
//  ScanView.swift
//  RoomLog
//
//  Created by 김도연 on 4/13/26.
//

import SwiftUI

struct ScanView: View {
    @State private var viewModel = ScanViewModel()

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(session: viewModel.session)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                statusBadge
                controls
            }
            .padding(.bottom, 52)
        }
        .onAppear { viewModel.setup() }
        .onDisappear { viewModel.tearDown() }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        switch viewModel.recordingState {
        case .idle:
            EmptyView()
        case .recording:
            Label("녹화 중", systemImage: "record.circle.fill")
                .foregroundStyle(.red)
                .badgeStyle()
        case .processing:
            Label("처리 중...", systemImage: "gear")
                .badgeStyle()
        case .done:
            Label("완료", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .badgeStyle()
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .lineLimit(2)
                .badgeStyle()
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        switch viewModel.recordingState {
        case .idle:
            recordButton

        case .recording:
            stopButton

        case .processing:
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
                .frame(height: 72)

        case .done(let url):
            HStack(spacing: 20) {
                Button("새 스캔") { viewModel.reset() }
                    .buttonStyle(.bordered)
                    .tint(.white)

                ShareLink(
                    item: url,
                    preview: SharePreview("scan.zip", image: Image(systemName: "doc.zipper"))
                ) {
                    Label("공유", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.white)
                }
            }

        case .failed:
            Button("다시 시도") { viewModel.startRecording() }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Buttons

    private var recordButton: some View {
        Button { viewModel.startRecording() } label: {
            Circle()
                .fill(.red)
                .frame(width: 72, height: 72)
                .overlay(Circle().strokeBorder(.white, lineWidth: 4))
        }
    }

    private var stopButton: some View {
        Button { viewModel.stopRecording() } label: {
            ZStack {
                Circle()
                    .strokeBorder(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)
                RoundedRectangle(cornerRadius: 6)
                    .fill(.red)
                    .frame(width: 30, height: 30)
            }
        }
    }
}

// MARK: - View Extension

private extension View {
    func badgeStyle() -> some View {
        self
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    ScanView()
}
