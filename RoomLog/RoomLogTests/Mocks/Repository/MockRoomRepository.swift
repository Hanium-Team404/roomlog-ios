//
//  MockRoomRepository.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Foundation
@testable import RoomLog

final class MockRoomRepository: RoomRepositoryProtocol {

    // MARK: - Call Tracking

    var getRoomDetailCallCount = 0
    var updateRoomCallCount = 0
    var deleteRoomCallCount = 0

    // MARK: - Captured Arguments

    var lastDeletedRoomId: Int?
    var lastUpdatedRoomId: Int?

    // MARK: - Stub Results

    var getRoomDetailResult: Result<RoomDetail, Error> = .success(
        RoomDetail(
            id: 1,
            name: "테스트 방",
            moveInDate: nil,
            moveOutDate: nil,
            thumbnailURL: nil,
            fileURL: nil,
            createdAt: Date(),
            latestScan: nil
        )
    )
    var updateRoomResult: Result<Void, Error> = .success(())
    var deleteRoomResult: Result<Void, Error> = .success(())

    // MARK: - RoomRepositoryProtocol

    func getRoomDetail(roomId: Int) async throws -> RoomDetail {
        getRoomDetailCallCount += 1
        return try getRoomDetailResult.get()
    }

    func updateRoom(roomId: Int, name: String, moveInDate: Date, moveOutDate: Date?) async throws {
        updateRoomCallCount += 1
        lastUpdatedRoomId = roomId
        try updateRoomResult.get()
    }

    func deleteRoom(roomId: Int) async throws {
        deleteRoomCallCount += 1
        lastDeletedRoomId = roomId
        try deleteRoomResult.get()
    }
}
