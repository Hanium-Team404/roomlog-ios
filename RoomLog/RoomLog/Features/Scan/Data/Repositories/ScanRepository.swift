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
    func uploadScan(houseId: Int, fileURL: URL) async throws -> ScanResult {
        let response = try await adapter.request(
            ScanTarget.uploadScan(houseId: houseId, fileURL: fileURL)
        )
        do {
            let dto = try decoder.decode(APIResponse<ScanResultResponseDTO>.self, from: response.data)
            return try dto.unwrap().toDomain()
        } catch let error as DecodingError {
            throw RepositoryError.decodingError(detail: String(describing: error))
        }
    }

    func getScanStatus(scanId: Int) async throws -> String {
        let response = try await adapter.request(ScanTarget.getScanStatus(scanId: scanId))
        do {
            let dto = try decoder.decode(APIResponse<ScanStatusResponseDTO>.self, from: response.data)
            return try dto.unwrap().status
        } catch let error as DecodingError {
            throw RepositoryError.decodingError(detail: String(describing: error))
        }
    }

    func getScanPreview(scanId: Int) async throws -> String {
        let response = try await adapter.request(ScanTarget.getScanPreview(scanId: scanId))
        do {
            let dto = try decoder.decode(APIResponse<ScanPreviewResponseDTO>.self, from: response.data)
            return try dto.unwrap().fileURL
        } catch let error as DecodingError {
            throw RepositoryError.decodingError(detail: String(describing: error))
        }
    }

    func cancelScan(scanId: Int) async throws {
        let response = try await adapter.request(ScanTarget.cancelScan(scanId: scanId))
        do {
            let dto = try decoder.decode(APIResponse<EmptyResult>.self, from: response.data)
            _ = try dto.unwrap()
        } catch let error as DecodingError {
            throw RepositoryError.decodingError(detail: String(describing: error))
        }
    }
}
