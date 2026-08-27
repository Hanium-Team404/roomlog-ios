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
            DefectReportDetail(id: 1, analysisID: 1, imageURL: nil, type: .crack, severity: .high, description: "벽면 균열 발견", repairCost: 80000, defectArea: 0.3, location: "거실 북쪽 벽", discoveredDate: nil, memo: nil, x: 0.3, y: 0.4, z: nil, region3d: []),
            DefectReportDetail(id: 2, analysisID: 1, imageURL: nil, type: .stain, severity: .medium, description: "화장실 천장 곰팡이", repairCost: 50000, defectArea: 0.2, location: "화장실 천장", discoveredDate: nil, memo: nil, x: 0.7, y: 0.2, z: nil, region3d: []),
            DefectReportDetail(id: 3, analysisID: 1, imageURL: nil, type: .peeling, severity: .low, description: "벽지 뜯김", repairCost: 20000, defectArea: 0.1, location: "침실 동쪽 벽", discoveredDate: nil, memo: nil, x: 0.5, y: 0.6, z: nil, region3d: [])
        ]
        return DefectReport(room: room, imageURL: nil, defectCount: defects.count, minRepairCost: 150000, repairArea: 0.6, defects: defects)
    }

    func getDefectReportDetail(roomId: Int) async throws -> DefectReportDetail {
        DefectReportDetail(
            id: roomId,
            analysisID: 1,
            imageURL: nil,
            type: .crack,
            severity: .medium,
            description: "벽면 균열 발견",
            repairCost: 50000,
            defectArea: 0.3,
            location: "거실 북쪽 벽",
            discoveredDate: nil,
            memo: nil,
            x: 0.3,
            y: 0.4,
            z: nil,
            region3d: []
        )
    }

    func requestAnalysis(inRoomId: Int, outRoomId: Int?) async throws -> (analysisId: Int, status: String) {
        return (analysisId: 1, status: "PENDING")
    }

    func getAnalysisStatus(analysisId: Int) async throws -> String {
        return "COMPLETED"
    }

    func getAnalysisResult(analysisId: Int) async throws -> AnalysisResult {
        AnalysisResult(
            analysisId: analysisId,
            roomId: 1,
            status: "COMPLETED",
            defectCount: 2,
            totalCost: 100000,
            totalArea: 0.5,
            defects: [
                DefectReportDetail(id: 1, analysisID: 1, imageURL: nil, type: .crack, severity: .high, description: "벽면 균열", repairCost: 60000, defectArea: 0.3, location: "거실 벽", discoveredDate: nil, memo: nil, x: nil, y: nil, z: nil, region3d: []),
                DefectReportDetail(id: 2, analysisID: 1, imageURL: nil, type: .stain, severity: .medium, description: "천장 얼룩", repairCost: 40000, defectArea: 0.2, location: "천장", discoveredDate: nil, memo: nil, x: nil, y: nil, z: nil, region3d: [])
            ],
            plyURL: nil,
            createdAt: Date()
        )
    }

    func getSelfRepairGuide(defectId: Int) async throws -> SelfRepairGuide {
        // 짝수 하자 ID는 자가 수리 가능, 홀수는 불가능으로 가정해 두 케이스를 모두 확인한다.
        guard defectId % 2 == 0 else {
            return SelfRepairGuide(
                defectId: defectId,
                isPossible: false,
                description: "해당 하자는 구조체 균열로, 안전상 위험이 있어 스스로 수리 불가",
                videos: [],
                items: [],
                totalCost: 0
            )
        }
        return SelfRepairGuide(
            defectId: defectId,
            isPossible: true,
            description: "해당 하자는 벽지 들뜸으로, 도배 풀과 벽지만 있으면 스스로 수리 가능",
            videos: [
                SelfRepairVideo(
                    title: "욕실 타일 깨짐 보수하는 방법! 이제 셀프로 해결하세요.",
                    urlString: "https://www.youtube.com/watch?v=L4Ro4hKoAvs",
                    channel: "이것도 꽉Fix",
                    thumbnailURLString: "https://i.ytimg.com/vi/L4Ro4hKoAvs/mqdefault.jpg"
                )
            ],
            items: [
                SelfRepairItem(name: "곰팡이 제거제", price: 8900, urlString: "https://www.coupang.com", imageURLString: nil),
                SelfRepairItem(name: "욕실용 실리콘", price: 11100, urlString: "https://www.gmarket.co.kr", imageURLString: nil)
            ],
            totalCost: 20000
        )
    }
}
