//
//  ScanRepository.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation
import Moya

final class ScanRepository: ScanRepositoryProtocol {
    // MARK: - Property
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function
    func uploadScan(houseId: Int, fileURL: URL) async throws(RepositoryError) -> ScanResult {
        try await adapter.requestDecoded(
            ScanTarget.uploadScan(houseId: houseId, fileURL: fileURL),
            as: ScanResultResponseDTO.self,
            decoder: decoder
        ).toDomain()
    }

    func getScanStatus(scanId: Int) async throws(RepositoryError) -> String {
        try await adapter.requestDecoded(
            ScanTarget.getScanStatus(scanId: scanId),
            as: ScanStatusResponseDTO.self,
            decoder: decoder
        ).status
    }

    func getScanPreview(scanId: Int) async throws(RepositoryError) -> String {
        try await adapter.requestDecoded(
            ScanTarget.getScanPreview(scanId: scanId),
            as: ScanPreviewResponseDTO.self,
            decoder: decoder
        ).fileURL
    }

    func cancelScan(scanId: Int) async throws(RepositoryError) {
        _ = try await adapter.requestDecoded(
            ScanTarget.cancelScan(scanId: scanId),
            as: EmptyResult.self,
            decoder: decoder
        )
    }
}
