//
//  MockDefectRepository.swift
//  RoomLog
//
//  Created by 송민교 on 4/22/26.
//

import Foundation

final class MockDefectRepository: DefectRepositoryProtocol {
    func getDefectRoomData() async throws -> [DefectRoomData] {
        [
            DefectRoomData(id: 1, title: "망고의 방", date: Date(timeIntervalSinceNow: -86400 * 3), thumbnailURL: nil),
            DefectRoomData(id: 2, title: "민교의 방", date: Date(timeIntervalSinceNow: -86400 * 10), thumbnailURL: nil),
            DefectRoomData(id: 3, title: "밍교의 방", date: Date(timeIntervalSinceNow: -86400 * 30), thumbnailURL: nil)
        ]
    }

    func getDefectReport(roomId: Int) async throws -> DefectReport {
        let room = DefectRoomData(id: roomId, title: "망고의 방", date: Date(), thumbnailURL: nil)
        let defects = [
            DefectReportDetail(id: "1", imageURL: nil, type: "균열", severity: .high, description: "벽면 균열 발견", repairCost: 80000, defectArea: 0.3, location: "거실 북쪽 벽", discoveredDate: nil, memo: nil, x: 0.3, y: 0.4, z: nil),
            DefectReportDetail(id: "2", imageURL: nil, type: "곰팡이", severity: .medium, description: "화장실 천장 곰팡이", repairCost: 50000, defectArea: 0.2, location: "화장실 천장", discoveredDate: nil, memo: nil, x: 0.7, y: 0.2, z: nil),
            DefectReportDetail(id: "3", imageURL: nil, type: "도배 손상", severity: .low, description: "벽지 뜯김", repairCost: 20000, defectArea: 0.1, location: "침실 동쪽 벽", discoveredDate: nil, memo: nil, x: 0.5, y: 0.6, z: nil)
        ]
        return DefectReport(room: room, imageURL: nil, defectCount: defects.count, minRepairCost: 150000, repairArea: 2.4, defects: defects)
    }

    func getDefectReportDetail(roomId: Int) async throws -> DefectReportDetail {
        DefectReportDetail(
            id: "\(roomId)",
            imageURL: nil,
            type: "균열",
            severity: .medium,
            description: "벽면 균열 발견",
            repairCost: 50000,
            defectArea: 0.5,
            location: "거실 북쪽 벽",
            discoveredDate: nil,
            memo: nil,
            x: 0.3,
            y: 0.4,
            z: nil
        )
    }
}
