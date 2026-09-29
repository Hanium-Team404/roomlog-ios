//
//  MockPLYFileCache.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 9/29/26.
//

import Foundation
@testable import RoomLog

/// 테스트 타깃은 기본 격리 설정이 없어 `Sendable` 요구를 채우기 위해 `@MainActor`로 격리한다.
@MainActor
final class MockPLYFileCache: PLYFileCacheProtocol {

    // MARK: - Call Tracking

    var cachedFileURLCallCount = 0
    var downloadCallCount = 0
    var removeCacheCallCount = 0
    var rekeyCallCount = 0

    // MARK: - Stub Results

    /// nil이면 캐시 미스
    var cachedResult: URL?
    var downloadResult: Result<URL, Error> = .success(
        FileManager.default.temporaryDirectory.appendingPathComponent("mock.ply")
    )

    // MARK: - PLYFileCacheProtocol
    // 요구사항이 nonisolated protocol에서 오면 witness도 nonisolated로 추론되므로
    // 클래스 격리를 명시해 상태 변경을 MainActor 안에서 수행한다 (async 요구사항이라 hop 허용).

    @MainActor
    func cachedFileURL(for roomId: Int) async -> URL? {
        cachedFileURLCallCount += 1
        return cachedResult
    }

    @MainActor
    func download(from remoteURL: URL, roomId: Int) async throws -> URL {
        downloadCallCount += 1
        return try downloadResult.get()
    }

    @MainActor
    func removeCache(for roomId: Int) async {
        removeCacheCallCount += 1
    }

    @MainActor
    func rekey(from oldRoomId: Int, to newRoomId: Int) async {
        rekeyCallCount += 1
    }
}
