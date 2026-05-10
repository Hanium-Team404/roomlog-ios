//
//  DefectRepositoryProtocol.swift
//
//
//  Created by 송민교 on 4/12/26.
//
import Foundation

protocol DefectRepositoryProtocol {
    /// 방 스캔 목록 조회
    func getDefectRoomData() async throws -> [DefectRoomData]

    /// 방 하자 목록 조회
    func getDefectReport(roomId: Int) async throws -> DefectReport

    /// 하자 상세 조회
    func getDefectReportDetail(roomId: Int) async throws -> DefectReportDetail
}
