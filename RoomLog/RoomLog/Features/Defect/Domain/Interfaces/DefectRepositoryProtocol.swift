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

    /// 하자 단건 조회. 방 하자 목록을 거치지 않는 진입(챗봇)용
    func getDefectDetail(defectId: Int) async throws -> DefectDetail

    /// 분석 생성 (단일 방 or 두 방 비교) — (analysisId, status)
    func requestAnalysis(inRoomId: Int, outRoomId: Int?) async throws -> (analysisId: Int, status: String)

    /// 분석 상태 조회
    func getAnalysisStatus(analysisId: Int) async throws -> String

    /// 분석 결과 조회
    func getAnalysisResult(analysisId: Int) async throws -> AnalysisResult

    /// 자가 수리 안내 조회
    func getSelfRepairGuide(defectId: Int) async throws -> SelfRepairGuide
}
