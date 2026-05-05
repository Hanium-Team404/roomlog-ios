//
//  DefectRepositoryProtocol.swift
//  
//
//  Created by 송민교 on 4/12/26.
//
import Foundation

protocol DefectRepositoryProtocol {
    /// 메인 하자 점검 방 조회
    func getDefectRoomData() async throws -> [DefectRoomData]
    
    /// 선택한 방 하자 정보 조회
    func getDefectReport(roomId: Int) async throws -> DefectReport
    
    /// 선택한 방 하자 정보 상세 조회
    func getDefectReportDetail(roomId: Int, reportId: Int) async throws -> DefectReportDetail
}
