//
//  RoomDetailViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import XCTest
@testable import RoomLog

@MainActor
final class RoomDetailViewModelTests: XCTestCase {

    private var provider: MockHomeUseCaseProvider!
    private var scanRepo: MockScanRepository!
    private var fileCache: MockUSDZFileCache!
    private var sut: RoomDetailViewModel!

    override func setUp() {
        super.setUp()
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

    // MARK: - load: roomDetail 조회

    func test_load_성공시_roomDetail이_설정된다() async {
        let detail = RoomDetail(
            id: 1, name: "거실", moveInDate: nil, moveOutDate: nil,
            fileURL: nil, createdAt: Date(), latestScan: nil
        )
        provider.getRoomDetailResult = .success(detail)

        await sut.load()

        XCTAssertEqual(sut.roomDetail?.name, "거실")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_load_실패시_errorMessage가_설정된다() async {
        provider.getRoomDetailResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "조회 실패"]))

        await sut.load()

        XCTAssertNil(sut.roomDetail)
        XCTAssertEqual(sut.errorMessage, "조회 실패")
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - load: resolveFileURL 분기

    func test_load_fileURL이_nil이고_latestScan이_없으면_다운로드하지_않는다() async {
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            fileURL: nil, createdAt: Date(), latestScan: nil
        )
        provider.getRoomDetailResult = .success(detail)

        await sut.load()

        XCTAssertNil(sut.localModelURL)
        XCTAssertEqual(scanRepo.getScanPreviewCallCount, 0)
        XCTAssertEqual(fileCache.downloadCallCount, 0)
    }

    /// 캐시가 있어도 download를 거쳐 원격 URL 변경 여부를 확인한다 (같으면 캐시 안에서 네트워크 없이 반환)
    func test_load_캐시가_있어도_download로_URL_변경을_확인한다() async {
        fileCache.cachedResult = URL(fileURLWithPath: "/tmp/room_1.usdz")
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            fileURL: "https://example.com/direct.usdz", createdAt: Date(),
            latestScan: ScanDetail(scanId: 99, status: "COMPLETED", createdAt: Date())
        )
        provider.getRoomDetailResult = .success(detail)

        await sut.load()

        XCTAssertEqual(fileCache.downloadCallCount, 1)
        XCTAssertEqual(scanRepo.getScanPreviewCallCount, 0)
        XCTAssertNotNil(sut.localModelURL)
        XCTAssertNil(sut.errorMessage)
    }

    /// 바뀐 모델을 못 받았을 때 옛 캐시로 대체하면 새 결과를 옛 메시 위에 그리게 되므로 에러로 노출한다
    func test_load_다운로드_실패시_캐시가_있어도_캐시로_대체하지_않는다() async {
        fileCache.cachedResult = URL(fileURLWithPath: "/tmp/room_1.usdz")
        fileCache.downloadResult = .failure(URLError(.notConnectedToInternet))
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            fileURL: "https://example.com/direct.usdz", createdAt: Date(),
            latestScan: nil
        )
        provider.getRoomDetailResult = .success(detail)

        await sut.load()

        XCTAssertNil(sut.localModelURL)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isDownloading)
    }

    func test_load_fileURL이_nil이고_latestScan이_있으면_scanPreview를_조회한다() async {
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            fileURL: nil, createdAt: Date(),
            latestScan: ScanDetail(scanId: 99, status: "COMPLETED", createdAt: Date())
        )
        provider.getRoomDetailResult = .success(detail)
        scanRepo.getScanPreviewResult = .success("https://example.com/mesh.usdz")

        await sut.load()

        XCTAssertEqual(scanRepo.getScanPreviewCallCount, 1)
        XCTAssertEqual(fileCache.downloadCallCount, 1)
        XCTAssertNotNil(sut.localModelURL)
        XCTAssertNil(sut.errorMessage)
    }

    func test_load_fileURL이_있으면_scanPreview를_조회하지_않는다() async {
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            fileURL: "https://example.com/direct.usdz", createdAt: Date(),
            latestScan: ScanDetail(scanId: 99, status: "COMPLETED", createdAt: Date())
        )
        provider.getRoomDetailResult = .success(detail)

        await sut.load()

        XCTAssertEqual(scanRepo.getScanPreviewCallCount, 0)
        XCTAssertEqual(fileCache.downloadCallCount, 1)
        XCTAssertNotNil(sut.localModelURL)
    }

    func test_load_다운로드_실패시_errorMessage가_설정되고_isDownloading이_해제된다() async {
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            fileURL: "https://example.com/direct.usdz", createdAt: Date(),
            latestScan: nil
        )
        provider.getRoomDetailResult = .success(detail)
        fileCache.downloadResult = .failure(URLError(.badServerResponse))

        await sut.load()

        XCTAssertNil(sut.localModelURL)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isDownloading)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - updateRoom

    func test_updateRoom_성공시_roomDetail이_갱신된다() async throws {
        let detail = RoomDetail(
            id: 1, name: "원래 이름", moveInDate: nil, moveOutDate: nil,
            fileURL: nil, createdAt: Date(), latestScan: nil
        )
        provider.getRoomDetailResult = .success(detail)
        await sut.load()

        let newDate = Date()
        try await sut.updateRoom(name: "새 이름", moveInDate: newDate, moveOutDate: nil)

        XCTAssertEqual(sut.roomDetail?.name, "새 이름")
        XCTAssertEqual(sut.roomDetail?.moveInDate, newDate)
    }

    func test_updateRoom_roomDetail이_nil이면_아무것도_안한다() async throws {
        // use case가 호출되면 throw로 테스트가 실패하도록 스텁 — guard가 실제로 호출을 막는지 증명
        provider.updateRoomResult = .failure(NSError(domain: "test", code: -1))

        try await sut.updateRoom(name: "이름", moveInDate: Date(), moveOutDate: nil)

        XCTAssertNil(sut.roomDetail)
    }

    func test_updateRoom_실패시_에러를_던진다() async {
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            fileURL: nil, createdAt: Date(), latestScan: nil
        )
        provider.getRoomDetailResult = .success(detail)
        await sut.load()
        provider.updateRoomResult = .failure(NSError(domain: "test", code: -1))

        do {
            try await sut.updateRoom(name: "실패", moveInDate: Date(), moveOutDate: nil)
            XCTFail("에러가 발생해야 합니다")
        } catch {
            XCTAssertEqual(sut.roomDetail?.name, "방") // 원래 이름 유지
        }
    }
}
