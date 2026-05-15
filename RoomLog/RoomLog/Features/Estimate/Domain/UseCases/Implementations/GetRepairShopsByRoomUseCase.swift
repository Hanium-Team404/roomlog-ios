import Foundation

final class GetRepairShopsByRoomUseCase: GetRepairShopsByRoomUseCaseProtocol {
    private let repository: EstimateRepositoryProtocol

    init(repository: EstimateRepositoryProtocol) {
        self.repository = repository
    }

    func execute(roomId: Int, type: String? = nil, radius: String? = "10km", sort: String? = "distance") async throws -> (shops: [RepairShop], analysisId: Int?) {
        try await repository.getRepairShopsByRoom(roomId: roomId, type: type, radius: radius, sort: sort)
    }
}
