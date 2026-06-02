//
//  EstimateRepositoryProtocol.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

protocol EstimateRepositoryProtocol {
    /// 수리 업체 리스트 조회
    func getRepairShops(analysisId: Int, type: String?, radius: String?, sort: String?) async throws -> [RepairShop]
    func getRepairShopsByRoom(roomId: Int, type: String?, radius: String?, sort: String?) async throws -> (shops: [RepairShop], analysisId: Int?)
    
    /// 견적 요청
    func createEstimate(message: String, roomId: Int, analysisId: Int?, defectIds: [Int], provider: RepairShop) async throws
    
    /// 견적 요청 목록 조회
    func getEstimates(roomId: Int) async throws -> [Estimate]
    
    func completeRepair(estimateId: Int, repairCost: Int, note: String?) async throws

    /// 견적 미리보기
    func previewEstimate(message: String, analysisId: Int, providerExternalId: String) async throws -> EstimatePreview

    /// 견적 상세 조회
    func getEstimateDetail(estimateId: Int) async throws -> EstimateDetail
}
