//
//  PLYFileCacheTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 9/29/26.
//

import Testing
import Foundation
@testable import RoomLog

/// 테스트마다 고유한 임시 디렉터리를 캐시 루트로 주입해 호스트 앱의 실제 Caches와 병렬 실행 간 간섭을 차단한다.
/// 원격 URL 자리에 로컬 `file://` URL을 넘겨 네트워크 없이 다운로드 경로를 실행한다.
final class PLYFileCacheTests {

    private let cacheDirectory: URL
    private let sut: PLYFileCache

    init() {
        cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PLYFileCacheTests-\(UUID().uuidString)", isDirectory: true)
        sut = PLYFileCache(cacheDirectory: cacheDirectory)
    }

    deinit {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    // MARK: - Helpers

    /// 다운로드 원본 역할을 하는 로컬 파일. 캐시 디렉터리 바깥에 두어 캐시 내용과 섞이지 않게 한다.
    private func makeSourceFile(named name: String, contents: String) throws -> URL {
        let sourceDirectory = cacheDirectory.deletingLastPathComponent()
            .appendingPathComponent("PLYFileCacheTests-source-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        let url = sourceDirectory.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Tests

    @Test func 캐시_미스면_다운로드해_캐시_디렉터리에_저장한다() async throws {
        let source = try makeSourceFile(named: "mesh.ply", contents: "ply-a")
        #expect(await sut.cachedFileURL(for: 1) == nil)

        let local = try await sut.download(from: source, roomId: 1)

        #expect(local == cacheDirectory.appendingPathComponent("room_1.ply"))
        #expect(FileManager.default.fileExists(atPath: local.path))
        #expect(try String(contentsOf: local, encoding: .utf8) == "ply-a")
        #expect(await sut.cachedFileURL(for: 1) == local)
    }

    @Test func 같은_원격URL로_다시_받으면_캐시를_재사용하고_다운로드하지_않는다() async throws {
        let source = try makeSourceFile(named: "mesh.ply", contents: "ply-a")
        let first = try await sut.download(from: source, roomId: 1)
        // 원본을 지워 두 번째 호출이 실제로 읽으러 가면 실패하게 만든다 — 캐시 히트 여부를 직접 증명
        try FileManager.default.removeItem(at: source)

        let second = try await sut.download(from: source, roomId: 1)

        #expect(second == first)
        #expect(try String(contentsOf: second, encoding: .utf8) == "ply-a")
    }

    @Test func 원격URL이_바뀌면_캐시가_있어도_다시_받는다() async throws {
        let oldSource = try makeSourceFile(named: "mesh.ply", contents: "ply-old")
        _ = try await sut.download(from: oldSource, roomId: 1)
        let newSource = try makeSourceFile(named: "mesh.ply", contents: "ply-new")

        let local = try await sut.download(from: newSource, roomId: 1)

        #expect(try String(contentsOf: local, encoding: .utf8) == "ply-new")
    }

    @Test func removeCache_후에는_cachedFileURL이_nil이다() async throws {
        let source = try makeSourceFile(named: "mesh.ply", contents: "ply-a")
        let local = try await sut.download(from: source, roomId: 1)

        await sut.removeCache(for: 1)

        #expect(await sut.cachedFileURL(for: 1) == nil)
        #expect(!FileManager.default.fileExists(atPath: local.path))
        #expect(!FileManager.default.fileExists(atPath: cacheDirectory.appendingPathComponent("room_1.source").path))
    }

    @Test func rekey_하면_새_roomId로_캐시가_이전되고_원래_키는_비워진다() async throws {
        let source = try makeSourceFile(named: "mesh.ply", contents: "ply-a")
        _ = try await sut.download(from: source, roomId: 100)

        await sut.rekey(from: 100, to: 7)

        #expect(await sut.cachedFileURL(for: 100) == nil)
        let moved = try #require(await sut.cachedFileURL(for: 7))
        #expect(try String(contentsOf: moved, encoding: .utf8) == "ply-a")
        // .source 사이드카도 함께 옮겨져야 같은 URL로 다시 받을 때 캐시 히트가 난다
        try FileManager.default.removeItem(at: source)
        #expect(try await sut.download(from: source, roomId: 7) == moved)
    }
}
