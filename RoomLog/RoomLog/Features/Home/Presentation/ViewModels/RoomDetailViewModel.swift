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
    private let fileCache: USDZFileCacheProtocol
    private var isPreview: Bool = false

    // MARK: - State

    private(set) var roomDetail: RoomDetail?
    private(set) var localModelURL: URL?
    private(set) var isLoading: Bool = false
    private(set) var isDownloading: Bool = false
    private(set) var errorMessage: String?
    var showEditSheet: Bool = false

    let roomId: Int

    // MARK: - Init

    init(
        roomId: Int,
        provider: HomeUseCaseProvider,
        scanRepository: ScanRepositoryProtocol,
        fileCache: USDZFileCacheProtocol = USDZFileCache.shared
    ) {
        self.roomId = roomId
        self.provider = provider
        self.scanRepository = scanRepository
        self.fileCache = fileCache
    }

    #if DEBUG
    init(preview roomDetail: RoomDetail?, localModelURL: URL? = nil, errorMessage: String? = nil) {
        self.roomId = roomDetail?.id ?? 0
        self.provider = MockHomeUseCaseProvider()
        self.scanRepository = MockScanRepository()
        self.fileCache = USDZFileCache.shared
        self.roomDetail = roomDetail
        self.localModelURL = localModelURL
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

            // fileURL 결정: roomDetail에 있으면 사용, 없으면 scan preview로 조회
            let fileURLString: String? = try await resolveFileURL(from: detail)

            if let urlString = fileURLString, let remoteURL = URL(string: urlString) {
                isDownloading = true
                // download가 캐시의 원본 URL과 비교해 같으면 네트워크 없이 캐시를, 바뀌었으면 새 파일을 돌려준다.
                // 실패 시 옛 캐시로 대체하지 않는다 (바뀐 모델 대신 옛 모델을 보여주면 안 되므로 에러로 노출)
                localModelURL = try await fileCache.download(from: remoteURL, roomId: roomId)
                isDownloading = false
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
