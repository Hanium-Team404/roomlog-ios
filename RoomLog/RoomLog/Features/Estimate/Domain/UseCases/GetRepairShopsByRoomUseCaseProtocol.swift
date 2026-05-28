import Foundation

protocol GetRepairShopsByRoomUseCaseProtocol {
    func execute(roomId: Int, type: String?, radius: String?, sort: String?) async throws -> (shops: [RepairShop], analysisId: Int?)
}

extension GetRepairShopsByRoomUseCaseProtocol {
    func execute(roomId: Int, type: String? = nil, radius: String? = nil, sort: String? = nil) async throws -> (shops: [RepairShop], analysisId: Int?) {
        try await execute(roomId: roomId, type: type, radius: radius, sort: sort)
    }
}
