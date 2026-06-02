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
    private var sut: RoomDetailViewModel!

    override func setUp() {
        super.setUp()
        provider = MockHomeUseCaseProvider()
        scanRepo = MockScanRepository()
        sut = RoomDetailViewModel(roomId: 1, provider: provider, scanRepository: scanRepo)
    }

    // MARK: - load: roomDetail 조회

    func test_load_성공시_roomDetail이_설정된다() async {
        let detail = RoomDetail(
            id: 1, name: "거실", moveInDate: nil, moveOutDate: nil,
            thumbnailURL: nil, fileURL: nil, createdAt: Date(), latestScan: nil
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
            thumbnailURL: nil, fileURL: nil, createdAt: Date(), latestScan: nil
        )
        provider.getRoomDetailResult = .success(detail)

        await sut.load()

        XCTAssertNil(sut.localPLYURL)
        XCTAssertEqual(scanRepo.getScanPreviewCallCount, 0)
    }

    func test_load_fileURL이_nil이고_latestScan이_있으면_scanPreview를_조회한다() async {
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            thumbnailURL: nil, fileURL: nil, createdAt: Date(),
            latestScan: ScanDetail(scanId: 99, status: "COMPLETED", createdAt: Date())
        )
        provider.getRoomDetailResult = .success(detail)
        scanRepo.getScanPreviewResult = .success("https://example.com/mesh.ply")

        await sut.load()

        XCTAssertEqual(scanRepo.getScanPreviewCallCount, 1)
    }

    func test_load_fileURL이_있으면_scanPreview를_조회하지_않는다() async {
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            thumbnailURL: nil, fileURL: "https://example.com/direct.ply", createdAt: Date(),
            latestScan: ScanDetail(scanId: 99, status: "COMPLETED", createdAt: Date())
        )
        provider.getRoomDetailResult = .success(detail)

        await sut.load()

        XCTAssertEqual(scanRepo.getScanPreviewCallCount, 0)
    }

    // MARK: - updateRoom

    func test_updateRoom_성공시_roomDetail이_갱신된다() async throws {
        let detail = RoomDetail(
            id: 1, name: "원래 이름", moveInDate: nil, moveOutDate: nil,
            thumbnailURL: nil, fileURL: nil, createdAt: Date(), latestScan: nil
        )
        provider.getRoomDetailResult = .success(detail)
        await sut.load()

        let newDate = Date()
        try await sut.updateRoom(name: "새 이름", moveInDate: newDate, moveOutDate: nil)

        XCTAssertEqual(sut.roomDetail?.name, "새 이름")
        XCTAssertEqual(sut.roomDetail?.moveInDate, newDate)
    }

    func test_updateRoom_roomDetail이_nil이면_아무것도_안한다() async throws {
        try await sut.updateRoom(name: "이름", moveInDate: Date(), moveOutDate: nil)

        XCTAssertNil(sut.roomDetail)
    }

    func test_updateRoom_실패시_에러를_던진다() async {
        let detail = RoomDetail(
            id: 1, name: "방", moveInDate: nil, moveOutDate: nil,
            thumbnailURL: nil, fileURL: nil, createdAt: Date(), latestScan: nil
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
