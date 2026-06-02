//
//  RoomListViewModelTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import XCTest
@testable import RoomLog

@MainActor
final class RoomListViewModelTests: XCTestCase {

    private var provider: MockHomeUseCaseProvider!
    private var sut: RoomListViewModel!

    override func setUp() {
        super.setUp()
        provider = MockHomeUseCaseProvider()
        sut = RoomListViewModel(houseId: 1, houseName: "초기 이름", provider: provider)
    }

    // MARK: - fetchRooms

    func test_fetchRooms_성공시_rooms와_houseName이_설정된다() async {
        let rooms = [
            RoomSummary(id: 1, name: "거실", thumbnailURL: nil, latestScan: nil, recentScanDate: nil, latestScanStatus: nil),
            RoomSummary(id: 2, name: "안방", thumbnailURL: nil, latestScan: nil, recentScanDate: nil, latestScanStatus: nil)
        ]
        provider.getHouseRoomsResult = .success(
            HouseRooms(rooms: rooms, houseId: 1, houseName: "서버 집 이름", totalCount: 2)
        )

        await sut.fetchRooms()

        XCTAssertEqual(sut.rooms.count, 2)
        XCTAssertEqual(sut.houseName, "서버 집 이름")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_fetchRooms_실패시_errorMessage가_설정된다() async {
        provider.getHouseRoomsResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "조회 실패"]))

        await sut.fetchRooms()

        XCTAssertTrue(sut.rooms.isEmpty)
        XCTAssertEqual(sut.errorMessage, "조회 실패")
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - deleteRoom

    func test_deleteRoom_성공시_목록에서_제거된다() async {
        let room = RoomSummary(id: 10, name: "삭제할 방", thumbnailURL: nil, latestScan: nil, recentScanDate: nil, latestScanStatus: nil)
        provider.getHouseRoomsResult = .success(
            HouseRooms(rooms: [room], houseId: 1, houseName: "집", totalCount: 1)
        )
        await sut.fetchRooms()

        await sut.deleteRoom(room)

        XCTAssertTrue(sut.rooms.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }

    func test_deleteRoom_실패시_errorMessage가_설정되고_목록은_유지된다() async {
        let room = RoomSummary(id: 10, name: "방", thumbnailURL: nil, latestScan: nil, recentScanDate: nil, latestScanStatus: nil)
        provider.getHouseRoomsResult = .success(
            HouseRooms(rooms: [room], houseId: 1, houseName: "집", totalCount: 1)
        )
        await sut.fetchRooms()
        provider.deleteRoomResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "삭제 권한 없음"]))

        await sut.deleteRoom(room)

        XCTAssertEqual(sut.rooms.count, 1)
        XCTAssertEqual(sut.errorMessage, "삭제 권한 없음")
    }
}
