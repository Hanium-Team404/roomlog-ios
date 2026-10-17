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
            .toolbarVisibility(.hidden, for: .tabBar)
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
            
            Group {
                if showsGuide {
                    ScanStatusBanner(systemImage: "move.3d", text: "녹화 버튼을 눌러 스캔을 시작하세요")
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: showsGuide)

            banners
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                statusBadge
                controls
            }
            .padding(.bottom, 52)
        }
    }

    private var showsGuide: Bool {
        viewModel.phase == .idle && !viewModel.showSessionError
    }

    // MARK: - Banners

    /// 거리 경고·세션 오류 배너. 화면 중앙에 표시되며 안내보다 위 레이어에 그려진다
    @ViewBuilder
    private var banners: some View {
        VStack(spacing: 12) {
            if viewModel.showDepthWarning {
                ScanStatusBanner(systemImage: "hand.raised.fill", text: "조금 더 떨어져주세요")
            }
            if viewModel.showSessionError {
                ScanStatusBanner(systemImage: "exclamationmark.triangle.fill", text: "카메라 오류가 발생해 다시 시작하는 중입니다")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showDepthWarning)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSessionError)
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
        .accessibilityLabel("촬영 시작")
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
        .accessibilityLabel("촬영 종료")
    }
}

