//
//  DefectRepository.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation
import Moya

final class DefectRepository: DefectRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func getDefectRoomData() async throws -> [DefectRoomData] {
        let response = try await adapter.request(DefectTarget.getDefectRoomData)
        let apiResponse: APIResponse<HomeDataResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<HomeDataResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().rooms.map { dto in
            DefectRoomData(
                id: dto.roomId,
                title: dto.name,
                date: dto.recentScanDate.flatMap { Date.fromServerDateTime($0) } ?? Date(),
                thumbnailURL: dto.thumbnailURL
            )
        }
    }

    func getDefectReport(roomId: Int) async throws -> DefectReport {
        let response = try await adapter.request(DefectTarget.getDefectReport(roomId: roomId))
        let apiResponse: APIResponse<DefectReportResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<DefectReportResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().toDomain()
    }

    func getDefectReportDetail(roomId: Int) async throws -> DefectReportDetail {
        throw RepositoryError.decodingError(detail: "개별 하자 조회 API 미지원")
    }
}
