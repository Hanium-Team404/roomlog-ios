//
//  PLYFileCache.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import Foundation

actor PLYFileCache {

    static let shared = PLYFileCache()

    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("PLYFiles", isDirectory: true)
    }

    // MARK: - Public

    /// 캐시된 파일 경로 반환. 없으면 nil.
    func cachedFileURL(for roomId: Int) -> URL? {
        let url = fileURL(for: roomId)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// 서버 URL에서 .ply 파일 다운로드 후 캐시. 캐시된 로컬 경로 반환.
    func download(from remoteURL: URL, roomId: Int) async throws -> URL {
        if let cached = cachedFileURL(for: roomId) {
            return cached
        }

        let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            try? FileManager.default.removeItem(at: tempURL)
            throw URLError(.badServerResponse)
        }
        let destination = fileURL(for: roomId)

        try ensureCacheDirectory()

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: tempURL, to: destination)

        return destination
    }

    /// 특정 방의 캐시 삭제
    func removeCache(for roomId: Int) {
        let url = fileURL(for: roomId)
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Private

    private func fileURL(for roomId: Int) -> URL {
        cacheDirectory.appendingPathComponent("room_\(roomId).ply")
    }

    private func ensureCacheDirectory() throws {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
}
