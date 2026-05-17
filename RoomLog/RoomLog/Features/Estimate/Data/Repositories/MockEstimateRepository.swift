import Foundation

final class MockEstimateRepository: EstimateRepositoryProtocol {
    var mockShops: [RepairShop] = [
        RepairShop(externalId: "1", name: "프로 인테리어", phone: "010-1234-5678", address: "서울시 강남구 테헤란로 123", latitude: 37.5006, longitude: 127.0367, imageURL: nil, distance: 350),
        RepairShop(externalId: "2", name: "홈닥터 리모델링", phone: "010-2345-6789", address: "서울시 서초구 반포대로 56", latitude: 37.5045, longitude: 127.0044, imageURL: nil, distance: 820),
        RepairShop(externalId: "3", name: "강남 인테리어", phone: "010-3456-7890", address: "서울시 강남구 신사동 568", latitude: 37.5172, longitude: 127.0473, imageURL: nil, distance: 1200),
        RepairShop(externalId: "4", name: "서초 리폼센터", phone: "010-4567-8901", address: "서울시 서초구 방배로 78", latitude: 37.4805, longitude: 126.9970, imageURL: nil, distance: 1500),
        RepairShop(externalId: "5", name: "한강 건축자재", phone: "010-5678-9012", address: "서울시 용산구 이촌로 45", latitude: 37.5169, longitude: 126.9690, imageURL: nil, distance: 2300),
    ]

    func getRepairShops(analysisId: Int, type: String?, radius: String?, sort: String?) async throws -> [RepairShop] {
        mockShops
    }

    func getRepairShopsByRoom(roomId: Int, type: String?, radius: String?, sort: String?) async throws -> (shops: [RepairShop], analysisId: Int?) {
        (shops: mockShops, analysisId: nil)
    }

    func getEstimates() async throws -> [Estimate] {
        [
            Estimate(id: 1, status: .sent, message: "균열 수리 문의", defectType: "벽지 찢어짐", defectSeverity: .high, defectLocation: "거실 벽면 북서부", repairCost: 15000, providerName: "홈케어 닥터스", providerPhone: "010-1234-5678", providerAddress: "서울시 강남구 테헤란로 123", createdAt: Date()),
            Estimate(id: 2, status: .sent, message: "곰팡이 제거 문의", defectType: "벽지 찢어짐", defectSeverity: .high, defectLocation: "거실 벽면 북서부", repairCost: 15000, providerName: "홈케어 닥터스", providerPhone: "010-2345-6789", providerAddress: "서울시 서초구 반포대로 56", createdAt: Date(timeIntervalSinceNow: -86400 * 7)),
            Estimate(id: 3, status: .completed, message: "도배 손상 문의", defectType: "벽지 찢어짐", defectSeverity: .medium, defectLocation: "거실 벽면 북서부", repairCost: 15000, providerName: "홈케어 닥터스", providerPhone: "010-3456-7890", providerAddress: "서울시 강남구 신사동 568", createdAt: Date(timeIntervalSinceNow: -86400 * 14)),
            Estimate(id: 4, status: .completed, message: "균열 수리 문의", defectType: "벽지 찢어짐", defectSeverity: .low, defectLocation: "거실 벽면 북서부", repairCost: 15000, providerName: "홈케어 닥터스", providerPhone: "010-4567-8901", providerAddress: "서울시 서초구 방배로 78", createdAt: Date(timeIntervalSinceNow: -86400 * 30)),
        ]
    }

    func completeRepair(estimateId: Int) async throws {}

    func createEstimate(message: String, roomId: Int, analysisId: Int?, defectIds: [Int], provider: RepairShop) async throws {}
}
