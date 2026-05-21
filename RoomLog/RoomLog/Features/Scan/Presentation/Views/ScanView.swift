//
//  ScanView.swift
//  RoomLog
//
//  Created by 김도연 on 4/13/26.
//

import SwiftUI

struct ScanView: View {
    @State private var viewModel: ScanViewModel
    @State private var showRecordedAlert: Bool = false

    init(
        houseId: Int,
        processingManager: ScanProcessingManager,
        onStartConversion: @escaping () -> Void
    ) {
        self._viewModel = .init(
            wrappedValue: ScanViewModel(
                houseId: houseId,
                processingManager: processingManager,
                onStartConversion: onStartConversion
            )
        )
    }

    #if DEBUG
    init(preview phase: ScanViewModel.Phase) {
        self._viewModel = .init(wrappedValue: ScanViewModel(preview: phase))
    }
    #endif

    private var recordingTimeString: String {
        let seconds = viewModel.recordingSeconds
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", min, sec)
    }

    // MARK: - Body

    var body: some View {
        scanPhase
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.setup() }
            .onDisappear { viewModel.tearDown() }
            .onChange(of: viewModel.phase) {
                if viewModel.phase == .recorded {
                    showRecordedAlert = true
                }
            }
            .alert("촬영 완료", isPresented: $showRecordedAlert) {
                Button("다시 촬영", role: .cancel) {
                    viewModel.reset()
                }
                Button("3D 변환 시작") {
                    viewModel.startConversion()
                }
                .keyboardShortcut(.defaultAction)
            } message: {
                Text("3D 변환을 시작하거나 다시 촬영할 수 있습니다")
            }
    }

    // MARK: - Scan Phase

    private var scanPhase: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(session: viewModel.session)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                statusBadge
                controls
            }
            .padding(.bottom, 52)
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()
        case .recording:
            Label(recordingTimeString, systemImage: "record.circle.fill")
                .foregroundStyle(.red)
                .badgeStyle()
        case .recorded:
            EmptyView()
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        switch viewModel.phase {
        case .idle:
            recordButton
        case .recording:
            stopButton
        case .recorded:
            EmptyView()
        }
    }

    // MARK: - Buttons

    private var recordButton: some View {
        Button {
            viewModel.startRecording()
        } label: {
            Circle()
                .fill(.red)
                .frame(width: 72, height: 72)
                .overlay(Circle().strokeBorder(.white, lineWidth: 4))
        }
    }

    private var stopButton: some View {
        Button {
            viewModel.stopRecording()
        } label: {
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
