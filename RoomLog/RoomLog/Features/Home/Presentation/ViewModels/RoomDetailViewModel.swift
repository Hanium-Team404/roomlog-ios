//
//  RoomDetailViewModel.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

@Observable
final class RoomDetailViewModel {

    // MARK: - Dependencies

    private let provider: HomeUseCaseProvider
    private let scanRepository: ScanRepositoryProtocol
    private let fileCache = PLYFileCache.shared
    private var isPreview: Bool = false

    // MARK: - State

    private(set) var roomDetail: RoomDetail?
    private(set) var localPLYURL: URL?
    private(set) var isLoading: Bool = false
    private(set) var isDownloading: Bool = false
    private(set) var errorMessage: String?
    var showEditSheet: Bool = false

    let roomId: Int

    // MARK: - Init

    init(roomId: Int, provider: HomeUseCaseProvider, scanRepository: ScanRepositoryProtocol) {
        self.roomId = roomId
        self.provider = provider
        self.scanRepository = scanRepository
    }

    #if DEBUG
    init(preview roomDetail: RoomDetail?, localPLYURL: URL? = nil, errorMessage: String? = nil) {
        self.roomId = roomDetail?.id ?? 0
        self.provider = MockHomeUseCaseProvider()
        self.scanRepository = MockScanRepository()
        self.roomDetail = roomDetail
        self.localPLYURL = localPLYURL
        self.errorMessage = errorMessage
        self.isPreview = true
    }
    #endif

    // MARK: - Actions

    @MainActor
    func load() async {
        guard !isPreview else { return }
        isLoading = true
        errorMessage = nil

        do {
            let detail = try await provider.makeGetRoomDetailUseCase().execute(roomId: roomId)
            roomDetail = detail

            // 캐시 확인
            if let cached = await fileCache.cachedFileURL(for: roomId) {
                localPLYURL = cached
            } else {
                // fileURL 결정: roomDetail에 있으면 사용, 없으면 scan preview로 조회
                let fileURLString: String? = try await resolveFileURL(from: detail)

                if let urlString = fileURLString, let remoteURL = URL(string: urlString) {
                    isDownloading = true
                    let localURL = try await fileCache.download(from: remoteURL, roomId: roomId)
                    localPLYURL = localURL
                    isDownloading = false
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isDownloading = false
        }

        isLoading = false
    }

    @MainActor
    func updateRoom(name: String, moveInDate: Date, moveOutDate: Date?) async throws {
        guard let detail = roomDetail else { return }
        try await provider.makeUpdateRoomUseCase().execute(
            roomId: roomId,
            name: name,
            moveInDate: moveInDate,
            moveOutDate: moveOutDate
        )
        roomDetail = RoomDetail(
            id: detail.id,
            name: name,
            moveInDate: moveInDate,
            moveOutDate: moveOutDate,
            thumbnailURL: detail.thumbnailURL,
            fileURL: detail.fileURL,
            createdAt: detail.createdAt,
            latestScan: detail.latestScan
        )
    }

    /// roomDetail.fileURL이 있으면 그대로, 없으면 latestScan으로 scan preview 조회
    private func resolveFileURL(from detail: RoomDetail) async throws -> String? {
        if let fileURL = detail.fileURL {
            return fileURL
        }
        if let scan = detail.latestScan {
            return try await scanRepository.getScanPreview(scanId: scan.scanId)
        }
        return nil
    }
}
