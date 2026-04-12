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
    func getDefectRoomData() async throws -> DefectRoomData {
        // TODO: DTO 확정 후 실제 디코딩 구현
        let _ = try await adapter.request(DefectTarget.getDefectRoomData)
        fatalError("getDefectRoomData: DTO 미구현")
    }

    func getDefectReport(roomId: Int) async throws -> DefectReport {
        // TODO: DTO 확정 후 실제 디코딩 구현
        let _ = try await adapter.request(DefectTarget.getDefectReport(roomId: roomId))
        fatalError("getDefectReport: DTO 미구현")
    }

    func getDefectReportDetail(roomId: Int, reportId: Int) async throws -> DefectReportDetail {
        // TODO: DTO 확정 후 실제 디코딩 구현
        let _ = try await adapter.request(DefectTarget.getDefectReportDetail(roomId: roomId, reportId: reportId))
        fatalError("getDefectReportDetail: DTO 미구현")
    }
}
