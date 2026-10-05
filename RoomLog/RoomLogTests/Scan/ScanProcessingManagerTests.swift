//
//  ScanProcessingManagerTests.swift
//  RoomLogTests
//
//  Created by 김도연 on 5/31/26.
//

import Testing
import Foundation
@testable import RoomLog

@MainActor
final class ScanProcessingManagerTests {

    private let mockRepo: MockScanRepository
    private let mockCache: MockPLYFileCache
    private let mockContinuation: MockScanBackgroundContinuation
    private let mockNotifier: MockScanCompletionNotifier
    /// 테스트마다 고유한 suite·디렉토리를 사용해 호스트 앱 오염과 병렬 실행 간 간섭을 차단
    private let suiteName: String
    private let defaults: UserDefaults
    private let tempDirectory: URL
    private let store: ScanArtifactStore
    private let sut: ScanProcessingManager

    init() throws {
        suiteName = "ScanProcessingManagerTests-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        mockRepo = MockScanRepository()
        mockCache = MockPLYFileCache()
        mockContinuation = MockScanBackgroundContinuation()
        mockNotifier = MockScanCompletionNotifier()
        store = ScanArtifactStore(
            userDefaults: defaults,
            baseDirectory: tempDirectory,
            legacyDocumentsDirectory: tempDirectory.appendingPathComponent("Documents", isDirectory: true)
        )
        sut = ScanProcessingManager(
            pollConfig: .init(interval: .milliseconds(50)),
            artifactStore: store,
            fileCache: mockCache,
            backgroundContinuation: mockContinuation,
            completionNotifier: mockNotifier
        )
        sut.configure(scanRepository: mockRepo)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    /// 조건이 충족될 때까지 폴링 대기. 충족 즉시 반환하므로 고정 sleep과 달리
    /// CI 부하에 따른 flakiness 없이 빠르게 끝난다. 타임아웃 시 Issue를 기록한다.
    private func waitUntil(
        timeout: Duration = .seconds(5),
        _ condition: () -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while !condition() {
            if clock.now >= deadline {
                Issue.record("waitUntil 타임아웃: \(timeout) 내에 조건이 충족되지 않았습니다")
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    // MARK: - resumePolling (폴링 재개)

    @Test func resumePolling_호출시_polling_상태가_된다() async throws {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.resumePolling(scanId: 100, houseId: 1)

        #expect(sut.activeScan?.scanId == 100)
        #expect(sut.activeScan?.houseId == 1)
        #expect(sut.activeScan?.phase == .polling)
        // 상태만 바뀌고 루프가 돌지 않는 회귀를 잡기 위해 실제 상태 조회를 관측한다
        try await waitUntil { mockRepo.getScanStatusCallCount > 0 }
        #expect(mockRepo.getScanStatusCallCount > 0, "폴링 루프가 실제로 상태 조회를 시작해야 합니다")
        // 시동된 폴링 루프 정리 (안 하면 maxAttempts 소진까지 백그라운드에서 계속 돈다)
        sut.clear()
    }

    // MARK: - cancel

    @Test func cancel_호출시_activeScan이_nil이_된다() {
        sut.resumePolling(scanId: 100, houseId: 1)

        sut.cancel()

        #expect(sut.activeScan == nil)
        #expect(store.restore() == nil)
    }

    @Test func cancel후_매니저가_해제돼도_서버취소_요청이_나간다() async {
        var manager: ScanProcessingManager? = ScanProcessingManager(artifactStore: store, fileCache: mockCache)
        manager?.configure(scanRepository: mockRepo)
        manager?.setActiveScan(.init(scanId: 5, houseId: 1, phase: .polling))

        // 로그아웃: cancel 직후 DI 캐시 해제로 매니저가 사라지는 상황
        weak let released = manager
        let serverCancel = manager?.cancel()
        manager = nil
        // 요청이 끝나기 전에 해제됐음을 먼저 확인 — Task 종료 후에 검사하면 해제 전제가 증명되지 않는다
        #expect(released == nil, "cancel Task가 매니저를 붙잡고 있으면 안 됩니다")
        await serverCancel?.value

        #expect(mockRepo.cancelScanCallCount == 1)
    }

    // MARK: - clear

    @Test func clear_호출시_상태가_초기화된다() {
        store.save(.polling(scanId: 1, houseId: 1))
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 1, houseId: 1,
                phase: .completed(fileURL: URL(fileURLWithPath: "/tmp/test.ply"))
            )
        )

        sut.clear()

        #expect(sut.activeScan == nil)
        #expect(store.restore() == nil, "소비된 스캔의 기록이 남으면 재시작 시 되살아난다")
    }

    // MARK: - 폴링 타임아웃

    @Test func 폴링_타임아웃시_서버스캔을_파괴하지_않고_재시도할_수_있다() async throws {
        let sut = ScanProcessingManager(
            pollConfig: .init(maxAttempts: 2, interval: .milliseconds(10)),
            artifactStore: store,
            fileCache: mockCache
        )
        sut.configure(scanRepository: mockRepo)
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.resumePolling(scanId: 3, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed(let failure) = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        #expect(failure.userMessage == "처리 시간이 초과되었습니다")
        #expect(mockRepo.cancelScanCallCount == 0, "타임아웃이 서버 스캔을 취소하면 안 됩니다")
        #expect(sut.canRetry, "타임아웃은 재폴링으로 재시도할 수 있어야 합니다")
        #expect(store.restore() == .polling(scanId: 3, houseId: 1), "기록이 유지되어야 재시작 복구가 가능합니다")
    }

    // MARK: - 재시작 복구

    @Test func 재시작시_폴링기록이_있으면_configure만으로_폴링이_재개된다() async throws {
        store.save(.polling(scanId: 7, houseId: 3))
        mockRepo.getScanStatusResult = .success("PROCESSING")

        // 앱 재시작 시뮬레이션: 같은 스토어로 새 매니저를 구성 — resumePolling 없이 configure만 호출한다
        let restored = ScanProcessingManager(
            pollConfig: .init(interval: .milliseconds(50)),
            artifactStore: store,
            fileCache: mockCache
        )
        restored.configure(scanRepository: mockRepo)

        #expect(restored.activeScan?.scanId == 7)
        #expect(restored.activeScan?.houseId == 3)
        #expect(restored.activeScan?.phase == .polling)
        try await waitUntil { mockRepo.getScanStatusCallCount > 0 }
        #expect(mockRepo.getScanStatusCallCount > 0, "복원된 폴링은 실제로 상태 조회를 시작해야 합니다")
        restored.clear()
    }

    @Test func 재시작시_uploadReady인데_zip이_없으면_복원하지_않는다() {
        // zip 파일 없이 기록만 남긴 상황 (앱 삭제·컨테이너 정리 등)
        store.save(.uploadReady(zipFileName: "ghost.zip", houseId: 4))

        let restored = ScanProcessingManager(artifactStore: store, fileCache: mockCache)
        restored.configure(scanRepository: mockRepo)

        #expect(restored.activeScan == nil, "실체 없는 zip으로 재시도 UI를 띄우면 안 됩니다")
        #expect(store.restore() == nil, "죽은 기록은 정리돼야 합니다")
    }

    @Test func 업로드미완_기록이_있으면_재시도가능_실패로_복원된다() throws {
        let zipURL = store.zipDestinationURL()
        try Data("zip".utf8).write(to: zipURL)
        store.save(.uploadReady(zipFileName: zipURL.lastPathComponent, houseId: 4))

        // 앱 재시작 시뮬레이션: 같은 스토어로 새 매니저를 구성
        let restored = ScanProcessingManager(
            pollConfig: .init(interval: .milliseconds(50)),
            artifactStore: store,
            fileCache: mockCache
        )
        restored.configure(scanRepository: mockRepo)

        guard case .failed(let failure) = restored.activeScan?.phase else {
            Issue.record("업로드 미완 기록은 재시도 가능한 실패 상태로 복원돼야 합니다")
            return
        }
        #expect(restored.activeScan?.houseId == 4)
        #expect(failure.retrySource == .upload(zipURL: zipURL))
        #expect(restored.canRetry)
        #expect(FileManager.default.fileExists(atPath: zipURL.path), "sweep이 기록된 zip을 지우면 안 됩니다")
        // 복원은 상태만 되살리고 자동으로 업로드를 재개하지 않는다 — 재시도는 유저의 명시적 선택
        #expect(restored.currentTask == nil, "복원 시 Task를 띄우면 안 됩니다")
        #expect(mockRepo.uploadScanCallCount == 0, "복원 시 자동 업로드가 나가면 안 됩니다")
    }

    // MARK: - retry (업로드 실패)

    @Test func retry_업로드실패후_재시도하면_업로드가_다시_수행된다() async throws {
        mockRepo.uploadScanResult = .success(ScanResult(scanId: 10, status: "PROCESSING"))
        mockRepo.getScanStatusResult = .success("PROCESSING")
        let zipURL = store.zipDestinationURL()
        try Data("zip".utf8).write(to: zipURL)
        store.save(.uploadReady(zipFileName: zipURL.lastPathComponent, houseId: 1))
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 0, houseId: 1,
                phase: .failed(.init(userMessage: "업로드 실패", retrySource: .upload(zipURL: zipURL)))
            )
        )

        #expect(sut.canRetry)
        sut.retry()

        #expect(sut.activeScan?.phase == .uploading)
        try await waitUntil { sut.activeScan?.phase == .polling }
        #expect(mockRepo.uploadScanCallCount == 1)
        #expect(sut.activeScan?.scanId == 10)
        #expect(store.restore() == .polling(scanId: 10, houseId: 1), "업로드 성공 시 기록이 폴링으로 전환돼야 합니다")
        #expect(!FileManager.default.fileExists(atPath: zipURL.path), "업로드된 zip은 지워져야 합니다")
        sut.clear()
    }

    @Test func 재시도불가_업로드실패면_기록과_zip이_폐기된다() async throws {
        mockRepo.uploadScanResult = .failure(.decodingError(detail: "bad"))
        let zipURL = store.zipDestinationURL()
        try Data("zip".utf8).write(to: zipURL)
        store.save(.uploadReady(zipFileName: zipURL.lastPathComponent, houseId: 1))
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 0, houseId: 1,
                phase: .failed(.init(userMessage: "업로드 실패", retrySource: .upload(zipURL: zipURL)))
            )
        )

        sut.retry()
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        #expect(!sut.canRetry)
        #expect(store.restore() == nil, "재시도 불가 실패는 재시작 복구 대상이 아니어야 합니다")
        #expect(!FileManager.default.fileExists(atPath: zipURL.path))
    }

    @Test func configure_전에_실행하면_진행단계에_멈추지_않고_실패한다() async throws {
        let unconfigured = ScanProcessingManager(artifactStore: store, fileCache: mockCache)
        unconfigured.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 1, houseId: 1,
                phase: .failed(.init(userMessage: "상태 조회 실패", retrySource: .polling(scanId: 1)))
            )
        )

        unconfigured.retry()
        try await waitUntil { if case .failed = unconfigured.activeScan?.phase { true } else { false } }

        guard case .failed(let failure) = unconfigured.activeScan?.phase else { return }
        #expect(failure.userMessage == "스캔 서비스를 사용할 수 없습니다")
    }

    @Test func retry_재시도불가_실패면_거부된다() {
        let failure = ScanProcessingManager.ScanFailure(userMessage: "업로드 실패", retrySource: nil)
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 0, houseId: 1, phase: .failed(failure))
        )

        #expect(!sut.canRetry)
        sut.retry()

        // 거부된 retry는 start에 도달하지 않아 Task 자체가 안 생긴다 — sleep 없이 동기적으로 확정
        #expect(sut.currentTask == nil)
        #expect(mockRepo.uploadScanCallCount == 0)
        #expect(sut.activeScan?.phase == .failed(failure))
    }

    @Test func retry_failed_상태가_아니면_거부된다() {
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(scanId: 5, houseId: 1, phase: .polling)
        )

        #expect(!sut.canRetry)
        sut.retry()

        // 거부된 retry는 start에 도달하지 않아 Task 자체가 안 생긴다 — sleep 없이 동기적으로 확정
        #expect(sut.currentTask == nil)
        #expect(mockRepo.uploadScanCallCount == 0)
    }

    // MARK: - 성공 경로

    @Test func 폴링_COMPLETED후_프리뷰_다운로드가_끝나면_completed가_된다() async throws {
        mockRepo.getScanStatusResult = .success("COMPLETED")
        let localURL = tempDirectory.appendingPathComponent("room_7.ply")
        mockCache.downloadResult = .success(localURL)

        sut.resumePolling(scanId: 7, houseId: 1)
        try await waitUntil { if case .completed = sut.activeScan?.phase { true } else { false } }

        guard case .completed(let fileURL) = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        #expect(fileURL == localURL, "캐시가 돌려준 로컬 경로가 그대로 완료 상태에 실려야 합니다")
        #expect(mockRepo.getScanPreviewCallCount == 1)
        #expect(mockCache.downloadCallCount == 1)
        #expect(sut.activeScan?.scanId == 7)
        #expect(sut.activeScan?.houseId == 1)
    }

    // MARK: - retry (다운로드 실패)

    @Test func 다운로드실패시_pending이_유지되고_재다운로드를_재시도할_수_있다() async throws {
        mockRepo.getScanStatusResult = .success("COMPLETED")
        mockRepo.getScanPreviewResult = .failure(.transportError(code: .networkConnectionLost))

        sut.resumePolling(scanId: 7, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        // 기록을 유지해야 앱 재시작 시 폴링 재개 → 재다운로드로 복구할 수 있다
        #expect(store.restore() == .polling(scanId: 7, houseId: 1))
        #expect(sut.canRetry)
        let statusCallCountBeforeRetry = mockRepo.getScanStatusCallCount

        sut.retry()

        try await waitUntil { mockRepo.getScanPreviewCallCount == 2 }
        #expect(mockRepo.getScanPreviewCallCount == 2, "재시도 시 프리뷰 재다운로드를 시도해야 합니다")
        #expect(
            mockRepo.getScanStatusCallCount == statusCallCountBeforeRetry,
            "COMPLETED 확인 후의 다운로드 실패 재시도는 재폴링 없이 다운로드만 수행해야 합니다"
        )
    }

    @Test func 잘못된_파일URL이면_재시도_불가로_실패한다() async throws {
        mockRepo.getScanStatusResult = .success("COMPLETED")
        // URL(string: "")은 nil — 서버 데이터 결함 시나리오
        mockRepo.getScanPreviewResult = .success("")

        sut.resumePolling(scanId: 7, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed(let failure) = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        #expect(failure.userMessage == "잘못된 파일 URL")
        #expect(!sut.canRetry, "같은 응답으론 재시도해도 결과가 같으므로 재시도가 노출되면 안 됩니다")
        #expect(store.restore() == nil, "재시도 불가 실패는 재시작 시에도 되살아나면 안 됩니다")
    }

    @Test func 상태조회_연속실패시_pending이_유지되고_재시도할_수_있다() async throws {
        mockRepo.getScanStatusResult = .failure(.transportError(code: .networkConnectionLost))

        sut.resumePolling(scanId: 9, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        guard case .failed = sut.activeScan?.phase else { return } // 타임아웃 Issue는 waitUntil이 기록
        // 일시적 네트워크 문제일 수 있으므로 기록을 유지해 재시도·재시작 복구가 가능해야 한다
        #expect(store.restore() == .polling(scanId: 9, houseId: 1))
        #expect(sut.canRetry)

        let callCountBeforeRetry = mockRepo.getScanStatusCallCount
        sut.retry()

        #expect(sut.activeScan?.phase == .polling)
        try await waitUntil { mockRepo.getScanStatusCallCount > callCountBeforeRetry }
        #expect(mockRepo.getScanStatusCallCount > callCountBeforeRetry, "재시도 시 재폴링부터 수행해야 합니다")
        sut.clear()
    }

    // MARK: - 백그라운드 연장

    private typealias Display = MockScanBackgroundContinuation.Display

    /// 업로드 실패 후 재시도 대기 상태를 만든다 (zip·기록·실패 상태)
    private func prepareUploadRetry() throws {
        let zipURL = store.zipDestinationURL()
        try Data("zip".utf8).write(to: zipURL)
        store.save(.uploadReady(zipFileName: zipURL.lastPathComponent, houseId: 1))
        sut.setActiveScan(
            ScanProcessingManager.ActiveScan(
                scanId: 0, houseId: 1,
                phase: .failed(.init(userMessage: "업로드 실패", retrySource: .upload(zipURL: zipURL)))
            )
        )
    }

    @Test func 생성_대기중에도_연장을_유지하고_폴링할수록_진행률이_오른다() async throws {
        mockRepo.uploadScanResult = .success(ScanResult(scanId: 10, status: "PROCESSING"))
        mockRepo.getScanStatusResult = .success("PROCESSING")
        try prepareUploadRetry()

        sut.retry()
        try await waitUntil { mockRepo.getScanStatusCallCount >= 1 }

        // 목 저장소는 전송량을 보고하지 않으므로 업로드가 끝까지 전송된 상황을 직접 만든다
        let uploadProgress = try #require(mockRepo.lastUploadProgress)
        uploadProgress.totalUnitCount = 100
        uploadProgress.completedUnitCount = 100
        let tracked = try #require(mockContinuation.trackedProgresses.first)
        let early = tracked.fractionCompleted
        let callCount = mockRepo.getScanStatusCallCount
        try await waitUntil { mockRepo.getScanStatusCallCount >= callCount + 2 }

        #expect(early > 0.4, "업로드가 끝난 뒤 첫 폴링부터 업로드 완료 지점(40%)을 넘어야 합니다")
        #expect(tracked.fractionCompleted > early, "생성 대기 중에도 폴링할수록 진행률이 올라야 합니다")
        #expect(tracked.fractionCompleted < 0.95, "완료 전에는 폴링 몫의 끝(95%)을 넘지 않아야 합니다")
        #expect(mockContinuation.endResults.isEmpty, "생성 대기 중에도 연장이 유지돼야 합니다")
        #expect(mockContinuation.displays.last == Display(title: "서버 처리 중", subtitle: "3D 모델을 생성하고 있습니다"))
        sut.clear()
    }

    @Test func 프리뷰_다운로드까지_끝나면_완료_문구로_바꾸고_성공으로_끝낸다() async throws {
        mockRepo.uploadScanResult = .success(ScanResult(scanId: 10, status: "PROCESSING"))
        mockRepo.getScanStatusResult = .success("COMPLETED")
        try prepareUploadRetry()

        sut.retry()
        try await waitUntil { if case .completed = sut.activeScan?.phase { true } else { false } }

        #expect(mockContinuation.displays.last == Display(title: "스캔 완료", subtitle: "3D 모델이 준비되었습니다"))
        #expect(mockContinuation.endResults == [true])
    }

    @Test func 업로드_실패시_실패_문구로_바꾸고_실패로_끝낸다() async throws {
        let error = RepositoryError.transportError(code: .networkConnectionLost)
        mockRepo.uploadScanResult = .failure(error)
        try prepareUploadRetry()

        sut.retry()
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        #expect(mockContinuation.displays.last == Display(title: "스캔 실패", subtitle: "업로드 실패: \(error.userMessage)"))
        #expect(mockContinuation.endResults == [false])
    }

    // MARK: - 완료 알림

    @Test func 프리뷰까지_끝나면_집_정보를_담아_완료_알림을_보낸다() async throws {
        mockRepo.getScanStatusResult = .success("COMPLETED")

        sut.resumePolling(scanId: 7, houseId: 3)
        try await waitUntil { if case .completed = sut.activeScan?.phase { true } else { false } }

        // 알림을 누르면 이 집의 상태 시트로 이동한다
        #expect(mockNotifier.notifications == [.init(title: "스캔 완료", body: "3D 모델이 준비되었습니다", houseId: 3)])
    }

    @Test func 실패로_끝나면_완료_알림을_보내지_않는다() async throws {
        mockRepo.getScanStatusResult = .success("FAILED")

        sut.resumePolling(scanId: 7, houseId: 1)
        try await waitUntil { if case .failed = sut.activeScan?.phase { true } else { false } }

        #expect(mockNotifier.notifications.isEmpty)
    }

    @Test func 업로드중_취소하면_성공으로_끝내지_않는다() async throws {
        // 취소를 무시하고 진행하면 끝까지 성공하도록 모든 단계를 성공으로 둔다
        mockRepo.uploadScanResult = .success(ScanResult(scanId: 10, status: "PROCESSING"))
        mockRepo.getScanStatusResult = .success("COMPLETED")
        try prepareUploadRetry()

        sut.retry()
        let task = try #require(sut.currentTask)
        sut.cancel()
        await task.value

        // 취소 후 늦게 도착한 업로드 응답이 처리를 이어가 연장을 성공으로 덮어쓰면 안 된다.
        // endResults는 연장이 끝난 뒤의 호출을 무시하므로 모든 호출 기록으로 검증한다
        #expect(mockContinuation.endResults == [false])
        #expect(mockContinuation.allEndCalls.contains(true) == false, "취소된 처리가 연장을 성공으로 끝냈습니다")
        #expect(mockNotifier.notifications.isEmpty, "취소된 처리가 완료 알림을 보냈습니다")
    }

    @Test func 폴링_재개는_백그라운드_연장을_요청하지_않는다() async throws {
        mockRepo.getScanStatusResult = .success("PROCESSING")

        sut.resumePolling(scanId: 1, houseId: 1)
        try await waitUntil { mockRepo.getScanStatusCallCount > 0 }

        #expect(mockContinuation.trackedProgresses.isEmpty)
        sut.clear()
    }
}
