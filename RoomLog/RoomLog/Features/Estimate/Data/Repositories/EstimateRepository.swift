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

    func getEstimates(roomId: Int) async throws -> [Estimate] {
        let response = try await adapter.request(EstimateTarget.getEstimates(roomId: roomId))
        let apiResponse: APIResponse<EstimateListResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<EstimateListResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().estimates.map { $0.toDomain() }
    }
    func completeRepair(estimateId: Int, repairCost: Int, note: String?) async throws {
        let body = CompleteRepairRequestDTO(repairCost: repairCost, note: note)
        let response = try await adapter.request(EstimateTarget.completeRepair(estimateId: estimateId, request: body))
        let apiResponse: APIResponse<CompleteRepairResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<CompleteRepairResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        _ = try apiResponse.unwrap()
    }

    func previewEstimate(message: String, analysisId: Int, providerExternalId: String) async throws -> EstimatePreview {
        let body = EstimatePreviewRequestDTO(message: message, analysisId: analysisId, providerExternalId: providerExternalId)
        let response: Response
        do {
            response = try await adapter.request(EstimateTarget.previewEstimate(request: body))
        } catch {
            let nsError = error as NSError
            throw RepositoryError.serverError(code: nsError.code, message: nsError.localizedDescription, errorCode: nil)
        }
        let apiResponse: APIResponse<EstimatePreviewResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<EstimatePreviewResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().toDomain()
    }

    func getEstimateDetail(estimateId: Int) async throws -> EstimateDetail {
        let response: Response
        do {
            response = try await adapter.request(EstimateTarget.getEstimateDetail(estimateId: estimateId))
        } catch {
            let nsError = error as NSError
            throw RepositoryError.serverError(code: nsError.code, message: nsError.localizedDescription, errorCode: nil)
        }
        let apiResponse: APIResponse<EstimateDetailResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<EstimateDetailResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().toDomain()
    }

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
