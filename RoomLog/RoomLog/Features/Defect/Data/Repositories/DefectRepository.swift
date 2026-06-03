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
        let apiResponse: APIResponse<DefectRoomListResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<DefectRoomListResponseDTO>.self, from: response.data)
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
        return try apiResponse.unwrap().toDomain(roomId: roomId)
    }

    func getDefectReportDetail(roomId: Int) async throws -> DefectReportDetail {
        throw RepositoryError.decodingError(detail: "개별 하자 조회 API 미지원")
    }

    func requestAnalysis(inRoomId: Int, outRoomId: Int?) async throws -> (analysisId: Int, status: String) {
        let response = try await adapter.request(DefectTarget.createAnalysis(inRoomId: inRoomId, outRoomId: outRoomId))
        let apiResponse: APIResponse<CreateAnalysisResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<CreateAnalysisResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        let result = try apiResponse.unwrap()
        return (analysisId: result.analysisId, status: result.status)
    }

    func getAnalysisStatus(analysisId: Int) async throws -> String {
        let response = try await adapter.request(DefectTarget.getAnalysisStatus(analysisId: analysisId))
        let apiResponse: APIResponse<AnalysisStatusResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<AnalysisStatusResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().status
    }

    func getAnalysisResult(analysisId: Int) async throws -> AnalysisResult {
        let response = try await adapter.request(DefectTarget.getAnalysisResult(analysisId: analysisId))
        let apiResponse: APIResponse<AnalysisResultResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<AnalysisResultResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().toDomain()
    }
}
