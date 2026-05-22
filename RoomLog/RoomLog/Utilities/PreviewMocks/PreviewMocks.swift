//
//  PreviewMocks.swift
//  RoomLog
//
//  Created by 김도연 on 5/13/26.
//

#if DEBUG
import Foundation

// MARK: - Mock ScanRepository

final class MockScanRepository: ScanRepositoryProtocol {
    func uploadScan(houseId: Int, fileURL: URL) async throws -> ScanResult {
        ScanResult(scanId: 1, status: "COMPLETED", fileURL: "")
    }

    func getScanStatus(scanId: Int) async throws -> String {
        "COMPLETED"
    }

    func getScanPreview(scanId: Int) async throws -> String {
        ""
    }

    func cancelScan(scanId: Int) async throws {}
}

// MARK: - Mock HomeUseCaseProvider

final class MockHomeUseCaseProvider: HomeUseCaseProvider {
    let rooms: [RoomSummary]

    init(rooms: [RoomSummary] = []) {
        self.rooms = rooms
    }

    func makeGetHousesUseCase() -> GetHousesUseCaseProtocol { fatalError() }
    func makeCreateHouseUseCase() -> CreateHouseUseCaseProtocol { fatalError() }
    func makeUpdateHouseUseCase() -> UpdateHouseUseCaseProtocol { fatalError() }
    func makeDeleteHouseUseCase() -> DeleteHouseUseCaseProtocol { fatalError() }
    func makeSetMainHouseUseCase() -> SetMainHouseUseCaseProtocol { fatalError() }
    func makeGetHouseRoomsUseCase() -> GetHouseRoomsUseCaseProtocol {
        MockGetHouseRoomsUseCase(rooms: rooms)
    }
    func makeCreateRoomUseCase() -> CreateRoomUseCaseProtocol { fatalError() }
    func makeGetRoomDetailUseCase() -> GetRoomDetailUseCaseProtocol { fatalError() }
    func makeUpdateRoomUseCase() -> UpdateRoomUseCaseProtocol { fatalError() }
    func makeDeleteRoomUseCase() -> DeleteRoomUseCaseProtocol {
        MockDeleteRoomUseCase()
    }
}

// MARK: - Mock UseCases

private struct MockGetHouseRoomsUseCase: GetHouseRoomsUseCaseProtocol {
    let rooms: [RoomSummary]
    func execute(houseId: Int) async throws -> HouseRooms {
        HouseRooms(rooms: rooms, houseId: houseId, houseName: "미리보기 집", totalCount: rooms.count)
    }
}

private struct MockDeleteRoomUseCase: DeleteRoomUseCaseProtocol {
    func execute(roomId: Int) async throws {}
}

// MARK: - Preview DIContainer

extension DIContainer {
    static func preview(processingManager: ScanProcessingManager = ScanProcessingManager()) -> DIContainer {
        let container = DIContainer()
        container.register(PathStore.self) { PathStore() }
        container.register(ScanProcessingManager.self) { processingManager }
        return container
    }
}

// MARK: - Sample Data

enum PreviewSampleData {
    static let rooms: [RoomSummary] = [
        RoomSummary(id: 1, name: "거실", thumbnailURL: nil, latestScan: LatestScan(scanId: 1), recentScanDate: Date(), latestScanStatus: "COMPLETED"),
        RoomSummary(id: 2, name: "안방", thumbnailURL: nil, latestScan: nil, recentScanDate: Date().addingTimeInterval(-86400), latestScanStatus: nil),
        RoomSummary(id: 3, name: "주방", thumbnailURL: nil, latestScan: LatestScan(scanId: 3), recentScanDate: Date().addingTimeInterval(-172800), latestScanStatus: "COMPLETED"),
    ]

    static let defects: [DefectReportDetail] = [
        DefectReportDetail(id: 1, imageURL: nil, type: "벽지 찢어짐", severity: .high, description: "벽지가 심하게 찢어져 있음", repairCost: 15000, defectArea: 0.24, location: "거실 벽면 북서부", discoveredDate: nil, memo: nil, x: 0.3, y: 0.4, z: nil),
        DefectReportDetail(id: 2, imageURL: nil, type: "바닥 찍힘", severity: .medium, description: "바닥에 찍힌 자국", repairCost: 15000, defectArea: 0.24, location: "거실 중앙부", discoveredDate: nil, memo: nil, x: 0.5, y: 0.6, z: nil),
        DefectReportDetail(id: 3, imageURL: nil, type: "벽지 찢어짐", severity: .low, description: "경미한 벽지 손상", repairCost: 15000, defectArea: 0.24, location: "거실 벽면 북서부", discoveredDate: nil, memo: nil, x: 0.7, y: 0.2, z: nil),
        DefectReportDetail(id: 4, imageURL: nil, type: "벽지 찢어짐", severity: .high, description: "큰 면적 벽지 손상", repairCost: 25000, defectArea: 0.35, location: "안방 벽면", discoveredDate: nil, memo: nil, x: nil, y: nil, z: nil),
        DefectReportDetail(id: 5, imageURL: nil, type: "바닥 찍힘", severity: .medium, description: "바닥 손상", repairCost: 10000, defectArea: 0.12, location: "주방 바닥", discoveredDate: nil, memo: nil, x: nil, y: nil, z: nil),
    ]

    static var defectReport: DefectReport {
        DefectReport(
            room: DefectRoomData(id: 1, title: "망고의 방", date: Date(), thumbnailURL: nil),
            imageURL: nil,
            defectCount: defects.count,
            minRepairCost: defects.reduce(0) { $0 + $1.repairCost },
            repairArea: Float(defects.reduce(0.0) { $0 + $1.defectArea }),
            defects: defects
        )
    }
}
#endif
