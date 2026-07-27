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

    /// 서버 URL에서 .ply 파일 다운로드 후 캐시. remoteURL이 이전에 캐시된 것과 같으면 재사용, 다르면 재다운로드.
    func download(from remoteURL: URL, roomId: Int) async throws -> URL {
        let destination = fileURL(for: roomId)
        if fileManager.fileExists(atPath: destination.path),
           cachedSourceURLString(for: roomId) == remoteURL.absoluteString {
            return destination
        }

        let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            try? FileManager.default.removeItem(at: tempURL)
            throw URLError(.badServerResponse)
        }

        try ensureCacheDirectory()

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: tempURL, to: destination)
        try? remoteURL.absoluteString.write(to: sourceURLFile(for: roomId), atomically: true, encoding: .utf8)

        return destination
    }

    /// 특정 방의 캐시 삭제
    func removeCache(for roomId: Int) {
        try? fileManager.removeItem(at: fileURL(for: roomId))
        try? fileManager.removeItem(at: sourceURLFile(for: roomId))
    }

    /// 임시 키(oldRoomId, 예: scanId)로 캐시된 파일을 새 roomId로 이전. 재다운로드 없이 그대로 재사용하기 위함.
    func rekey(from oldRoomId: Int, to newRoomId: Int) {
        guard oldRoomId != newRoomId else { return }

        let oldFile = fileURL(for: oldRoomId)
        let newFile = fileURL(for: newRoomId)
        if fileManager.fileExists(atPath: oldFile.path) {
            try? fileManager.removeItem(at: newFile)
            try? fileManager.moveItem(at: oldFile, to: newFile)
        }

        let oldSource = sourceURLFile(for: oldRoomId)
        let newSource = sourceURLFile(for: newRoomId)
        if fileManager.fileExists(atPath: oldSource.path) {
            try? fileManager.removeItem(at: newSource)
            try? fileManager.moveItem(at: oldSource, to: newSource)
        }
    }

    // MARK: - Private

    private func fileURL(for roomId: Int) -> URL {
        cacheDirectory.appendingPathComponent("room_\(roomId).ply")
    }

    /// 캐시된 파일이 어느 원격 URL에서 받아온 것인지 기록해두는 사이드카 파일 (캐시 무효화 판단용)
    private func sourceURLFile(for roomId: Int) -> URL {
        cacheDirectory.appendingPathComponent("room_\(roomId).source")
    }

    private func cachedSourceURLString(for roomId: Int) -> String? {
        try? String(contentsOf: sourceURLFile(for: roomId), encoding: .utf8)
    }

    private func ensureCacheDirectory() throws {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
}
