//
//  ComparisonRepository.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation
import Moya

final class ComparisonRepository: ComparisonRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func getHouses() async throws -> [House] {
        let response = try await adapter.request(HouseTarget.getHouses)
        let apiResponse: APIResponse<GetHousesResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<GetHousesResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().houses.map { $0.toDomain() }
    }

    func getRooms(houseId: Int) async throws -> [ComparisonScan] {
        let response = try await adapter.request(HouseTarget.getHouseRooms(houseId: houseId))
        let apiResponse: APIResponse<GetHouseRoomsResponseDTO>
        do {
            apiResponse = try decoder.decode(APIResponse<GetHouseRoomsResponseDTO>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().rooms.map { dto in
            ComparisonScan(
                id: dto.roomId,
                roomName: dto.name,
                scanDate: dto.recentScanDate.flatMap { Date.fromServerDate($0) },
                thumbnailURL: dto.fileURL
            )
        }
    }

    func getComparisonHistories(houseId: Int) async throws -> [ComparisonHistory] {
        let response = try await adapter.request(ComparisonTarget.getComparisonHistories(houseId: houseId))
        let apiResponse: APIResponse<[ComparisonHistoryDTO]>
        do {
            apiResponse = try decoder.decode(APIResponse<[ComparisonHistoryDTO]>.self, from: response.data)
        } catch {
            throw RepositoryError.decodingError(detail: error.localizedDescription)
        }
        return try apiResponse.unwrap().map { $0.toDomain() }
    }
}
