//
//  ScanPreviewView.swift
//  RoomLog
//
//  Created by 김도연 on 5/14/26.
//

import SwiftUI

struct ScanPreviewView: View {

    let fileURL: URL
    let scanId: Int
    let houseId: Int
    private var isPreview: Bool = false

    @Environment(\.di) private var di
    @State private var showSaveAlert: Bool = false
    @State private var showRescanAlert: Bool = false
    @State private var roomName: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    #if DEBUG
    init(preview: Bool) {
        self.fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("preview.ply")
        self.scanId = 1
        self.houseId = 1
        self.isPreview = true
    }
    #endif

    init(fileURL: URL, scanId: Int, houseId: Int) {
        self.fileURL = fileURL
        self.scanId = scanId
        self.houseId = houseId
    }

    private var provider: HomeUseCaseProvider {
        di.resolve(HomeUseCaseProvider.self)
    }

    private var processingManager: ScanProcessingManager {
        di.resolve(ScanProcessingManager.self)
    }

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    var body: some View {
        ZStack {
            PLYSceneView(fileURL: fileURL)
                .ignoresSafeArea(edges: .bottom)

            if isSaving {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("저장 중...")
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .navigationTitle("3D 미리보기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showRescanAlert = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .disabled(isSaving)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    roomName = ""
                    showSaveAlert = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .disabled(isSaving)
            }
        }
        .tint(.accent)
        .alert("방 이름 입력", isPresented: $showSaveAlert) {
            TextField("예: 거실, 안방", text: $roomName)
            Button("취소", role: .cancel) {}
            Button("저장") {
                Task { await saveRoom() }
            }
            .disabled(roomName.trimmingCharacters(in: .whitespaces).isEmpty)
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("저장할 방의 이름을 입력해주세요")
        }
        .alert("다시 스캔하기", isPresented: $showRescanAlert) {
            Button("취소", role: .cancel) {}
            Button("다시 스캔", role: .destructive) {
                processingManager.clear()
                _ = pathStore.homePath.popLast()
            }
        } message: {
            Text("현재 스캔 결과를 폐기하고\n방 목록으로 돌아갑니다")
        }
        .alert("저장 실패", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Save

    @MainActor
    private func saveRoom() async {
        let name = roomName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isSaving = true
        do {
            let roomId = try await provider.makeCreateRoomUseCase().execute(
                houseId: houseId,
                name: name,
                scanId: scanId
            )
            await PLYFileCache.shared.rekey(from: scanId, to: roomId)
            processingManager.clear()
            _ = pathStore.homePath.popLast()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
