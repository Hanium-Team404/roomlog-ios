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
        ZStack {
            ARViewContainer(session: viewModel.session)
                .ignoresSafeArea()

            if viewModel.showDepthWarning {
                VStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.title2)
                    Text("조금 더 떨어져주세요")
                        .font(.semibold, 15)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .glassEffect(.regular, in: .capsule)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showDepthWarning)
            }

            VStack(spacing: 20) {
                Spacer()
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
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .capsule)
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
                .frame(width: 52, height: 52)
                .frame(width: 68, height: 68)
                .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    private var stopButton: some View {
        Button {
            viewModel.stopRecording()
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(.red)
                .frame(width: 32, height: 32)
                .frame(width: 68, height: 68)
                .glassEffect(.regular.interactive(), in: .circle)
        }
    }
}

