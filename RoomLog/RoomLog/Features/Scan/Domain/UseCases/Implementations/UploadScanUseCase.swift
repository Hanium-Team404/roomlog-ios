//
//  UploadScanUseCase.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation
import ZIPFoundation

final class UploadScanUseCase: UploadScanUseCaseProtocol {
    // MARK: - Property
    private let repository: ScanRepositoryProtocol

    // MARK: - Init
    init(repository: ScanRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function
    func execute(datasetDirectory: URL, roomId: Int) async throws -> ScanResult {
        let zipURL = datasetDirectory
            .deletingLastPathComponent()
            .appendingPathComponent(datasetDirectory.lastPathComponent + ".zip")

        // 1. 데이터셋 폴더 → zip 압축 (백그라운드에서 실행)
        try await Task.detached(priority: .utility) {
            try FileManager.default.zipItem(at: datasetDirectory, to: zipURL)
        }.value

        defer {
            // 3. 업로드 성공/실패 무관하게 zip 파일 정리
            try? FileManager.default.removeItem(at: zipURL)
        }

        // 2. 서버 업로드
        return try await repository.uploadScan(roomId: roomId, zipFileURL: zipURL)
    }
}
