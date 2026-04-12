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
    func uploadScan(roomId: Int, zipFileURL: URL) async throws -> ScanResult {
        let response = try await adapter.request(ScanTarget.uploadScan(roomId: roomId, zipFileURL: zipFileURL))
        do {
            let dto = try decoder.decode(APIResponse<ScanResultResponseDTO>.self, from: response.data)
            return try dto.unwrap().toDomain()
        } catch let error as DecodingError {
            throw RepositoryError.decodingError(detail: String(describing: error))
        }
    }
}
