//
//  RoomDetailViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
import Testing
@testable import RoomLog

@MainActor
struct RoomDetailViewModelTests {

    private let provider: MockHomeUseCaseProvider
    private let scanRepo: MockScanRepository
    private let fileCache: MockUSDZFileCache
    private let sut: RoomDetailViewModel

    init() {
        provider = MockHomeUseCaseProvider()
        scanRepo = MockScanRepository()
        fileCache = MockUSDZFileCache()
        sut = RoomDetailViewModel(
            roomId: 1,
            provider: provider,
            scanRepository: scanRepo,
            fileCache: fileCache
        )
    }

    private func makeDetail(fileURL: String? = nil, latestScan: ScanDetail? = nil, name: String = "방") -> RoomDetail {
        RoomDetail(
            id: 1, name: name, moveInDate: nil, moveOutDate: nil,
            fileURL: fileURL, createdAt: Date(), latestScan: latestScan
        )
    }

    // MARK: - load: roomDetail 조회

    @Test
    func load_성공시_roomDetail이_설정된다() async {
        provider.getRoomDetailResult = .success(makeDetail(name: "거실"))

        await sut.load()

        #expect(sut.roomDetail?.name == "거실")
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test
    func load_실패시_errorMessage가_설정된다() async {
        provider.getRoomDetailResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "조회 실패"]))

        await sut.load()

        #expect(sut.roomDetail == nil)
        #expect(sut.errorMessage == "조회 실패")
        #expect(sut.isLoading == false)
    }

    // MARK: - load: resolveFileURL 분기

    @Test
    func load_fileURL이_nil이고_latestScan이_없으면_다운로드하지_않는다() async {
        provider.getRoomDetailResult = .success(makeDetail())

        await sut.load()

        #expect(sut.localModelURL == nil)
        #expect(scanRepo.getScanPreviewCallCount == 0)
        #expect(fileCache.downloadCallCount == 0)
    }

    /// 캐시가 있어도 download를 거쳐 원격 URL 변경 여부를 확인한다 (같으면 캐시 안에서 네트워크 없이 반환)
    @Test
    func load_캐시가_있어도_download로_URL_변경을_확인한다() async {
        fileCache.cachedResult = URL(fileURLWithPath: "/tmp/room_1.usdz")
        provider.getRoomDetailResult = .success(makeDetail(
            fileURL: "https://example.com/direct.usdz",
            latestScan: ScanDetail(scanId: 99, status: "COMPLETED", createdAt: Date())
        ))

        await sut.load()

        #expect(fileCache.downloadCallCount == 1)
        #expect(scanRepo.getScanPreviewCallCount == 0)
        #expect(sut.localModelURL != nil)
        #expect(sut.errorMessage == nil)
    }

    /// 바뀐 모델을 못 받았을 때 옛 캐시로 대체하면 새 결과를 옛 메시 위에 그리게 되므로 에러로 노출한다
    @Test
    func load_다운로드_실패시_캐시가_있어도_캐시로_대체하지_않는다() async {
        fileCache.cachedResult = URL(fileURLWithPath: "/tmp/room_1.usdz")
        fileCache.downloadResult = .failure(URLError(.notConnectedToInternet))
        provider.getRoomDetailResult = .success(makeDetail(fileURL: "https://example.com/direct.usdz"))

        await sut.load()

        #expect(sut.localModelURL == nil)
        #expect(sut.errorMessage != nil)
        #expect(sut.isDownloading == false)
    }

    @Test
    func load_fileURL이_nil이고_latestScan이_있으면_scanPreview를_조회한다() async {
        provider.getRoomDetailResult = .success(makeDetail(
            latestScan: ScanDetail(scanId: 99, status: "COMPLETED", createdAt: Date())
        ))
        scanRepo.getScanPreviewResult = .success("https://example.com/mesh.usdz")

        await sut.load()

        #expect(scanRepo.getScanPreviewCallCount == 1)
        #expect(fileCache.downloadCallCount == 1)
        #expect(sut.localModelURL != nil)
        #expect(sut.errorMessage == nil)
    }

    @Test
    func load_fileURL이_있으면_scanPreview를_조회하지_않는다() async {
        provider.getRoomDetailResult = .success(makeDetail(
            fileURL: "https://example.com/direct.usdz",
            latestScan: ScanDetail(scanId: 99, status: "COMPLETED", createdAt: Date())
        ))

        await sut.load()

        #expect(scanRepo.getScanPreviewCallCount == 0)
        #expect(fileCache.downloadCallCount == 1)
        #expect(sut.localModelURL != nil)
    }

    @Test
    func load_다운로드_실패시_errorMessage가_설정되고_isDownloading이_해제된다() async {
        provider.getRoomDetailResult = .success(makeDetail(fileURL: "https://example.com/direct.usdz"))
        fileCache.downloadResult = .failure(URLError(.badServerResponse))

        await sut.load()

        #expect(sut.localModelURL == nil)
        #expect(sut.errorMessage != nil)
        #expect(sut.isDownloading == false)
        #expect(sut.isLoading == false)
    }

    // MARK: - updateRoom

    @Test
    func updateRoom_성공시_roomDetail이_갱신된다() async throws {
        provider.getRoomDetailResult = .success(makeDetail(name: "원래 이름"))
        await sut.load()

        let newDate = Date()
        try await sut.updateRoom(name: "새 이름", moveInDate: newDate, moveOutDate: nil)

        #expect(sut.roomDetail?.name == "새 이름")
        #expect(sut.roomDetail?.moveInDate == newDate)
    }

    @Test
    func updateRoom_roomDetail이_nil이면_아무것도_안한다() async throws {
        // use case가 호출되면 throw로 테스트가 실패하도록 스텁 — guard가 실제로 호출을 막는지 증명
        provider.updateRoomResult = .failure(NSError(domain: "test", code: -1))

        try await sut.updateRoom(name: "이름", moveInDate: Date(), moveOutDate: nil)

        #expect(sut.roomDetail == nil)
    }

    @Test
    func updateRoom_실패시_에러를_던진다() async {
        provider.getRoomDetailResult = .success(makeDetail())
        await sut.load()
        provider.updateRoomResult = .failure(NSError(domain: "test", code: -1))

        do {
            try await sut.updateRoom(name: "실패", moveInDate: Date(), moveOutDate: nil)
            Issue.record("에러가 발생해야 합니다")
        } catch {
            #expect(sut.roomDetail?.name == "방", "실패하면 원래 이름을 유지해야 합니다")
        }
    }
}
