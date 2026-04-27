//
//  DefectRepository.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation
import Moya

final class DefectRepository: DefectRepositoryProtocol {
    // MARK: - Property
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init
    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function
    func getDefectRoomData() async throws -> [DefectRoomData] {
        // TODO: DTO 확정 후 실제 디코딩 구현
        let response = try await adapter.request(DefectTarget.getDefectRoomData)
        throw RepositoryError.decodingError(detail: "getDefectRoomData DTO 미구현. status=\(response.statusCode), bytes=\(response.data.count)")
    }

    func getDefectReport(roomId: Int) async throws -> DefectReport {
        // TODO: DTO 확정 후 실제 디코딩 구현
        let response = try await adapter.request(DefectTarget.getDefectReport(roomId: roomId))
        throw RepositoryError.decodingError(detail: "getDefectReport DTO 미구현. status=\(response.statusCode), bytes=\(response.data.count)")
    }

    func getDefectReportDetail(roomId: Int, reportId: Int) async throws -> DefectReportDetail {
        // TODO: DTO 확정 후 실제 디코딩 구현
        let response = try await adapter.request(DefectTarget.getDefectReportDetail(roomId: roomId, reportId: reportId))
        throw RepositoryError.decodingError(detail: "getDefectReportDetail DTO 미구현. status=\(response.statusCode), bytes=\(response.data.count)")
    }
}
