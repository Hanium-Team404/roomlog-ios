//
//  PLYFileCacheProtocol.swift
//  RoomLog
//
//  Created by Doyeon Kim on 9/29/26.
//

import Foundation

/// PLY 캐시의 주입 지점. 앱 타깃 기본 격리가 MainActor라 `nonisolated`로 선언해
/// actor 기반 캐시와 테스트 Mock이 모두 채택할 수 있게 한다.
nonisolated protocol PLYFileCacheProtocol: Sendable {

    func cachedFileURL(for roomId: Int) async -> URL?

    func download(from remoteURL: URL, roomId: Int) async throws -> URL

    func removeCache(for roomId: Int) async

    func rekey(from oldRoomId: Int, to newRoomId: Int) async
}

extension PLYFileCache: PLYFileCacheProtocol {}
