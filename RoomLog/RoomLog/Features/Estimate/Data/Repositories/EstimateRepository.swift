//
//  EstimateRepository.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation
import Moya

final class EstimateRepository: EstimateRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func getRepairShops(analysisId: Int, type: String?, radius: String?, sort: String?) async throws -> [RepairShop] {
        let response = try await adapter.request(EstimateTarget.getRepairShops(analysisId: analysisId, type: type, radius: radius, sort: sort))
        let apiResponse: APIResponse<RepairShopListResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<RepairShopListResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().repairShops.map { $0.toDomain() }
    }

    func getRepairShopsByRoom(roomId: Int, type: String?, radius: String?, sort: String?) async throws -> (shops: [RepairShop], analysisId: Int?) {
        let response = try await adapter.request(EstimateTarget.getRepairShopsByRoom(roomId: roomId, type: type, radius: radius, sort: sort))
        let apiResponse: APIResponse<RepairShopListResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<RepairShopListResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        let result = try apiResponse.unwrap()
        return (shops: result.repairShops.map { $0.toDomain() }, analysisId: result.analysisId)
    }

    // TODO: 서버 연동 시 실제 API 호출로 교체
    func getEstimates() async throws -> [Estimate] {
        try await MockEstimateRepository().getEstimates()
    }
    func completeRepair(estimateId: Int) async throws {}

    func createEstimate(message: String, roomId: Int, analysisId: Int?, defectIds: [Int], provider: RepairShop) async throws {
        let body = CreateEstimateRequestDTO(
            message: message,
            roomId: roomId,
            analysisId: analysisId,
            defectIds: defectIds,
            providerName: provider.name,
            providerPhone: provider.phone,
            providerAddress: provider.address
        )
        let response = try await adapter.request(EstimateTarget.createEstimate(request: body))
        let apiResponse: APIResponse<EmptyResult>
        do {
            apiResponse = try decoder.decode(APIResponse<EmptyResult>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        _ = try apiResponse.unwrap()
    }
}
