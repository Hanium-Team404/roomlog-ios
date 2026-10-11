//
//  DefectDetailResponseDTOTests.swift
//  RoomLogTests
//
//  Created by Doyeon Kim on 10/11/26.
//

import Testing
import Foundation
@testable import RoomLog

/// V06 하자 단건 조회 응답 디코딩. 하자 필드와 방 필드가 같은 JSON 객체에 평평하게 섞여 오므로
/// 두 디코딩이 한 컨테이너에서 함께 동작하는지 확인한다.
/// 앱 타겟이 기본 MainActor 격리라 DTO·모델 conformance를 쓰려면 테스트도 MainActor여야 한다
@MainActor
struct DefectDetailResponseDTOTests {

    private func decode(_ json: String) throws -> DefectDetail {
        let data = Data(json.utf8)
        let response = try JSONDecoder().decode(APIResponse<DefectDetailResponseDTO>.self, from: data)
        return try response.unwrap().toDomain()
    }

    @Test func 하자_필드와_방_필드를_함께_디코딩한다() throws {
        let json = """
        {
          "success": true, "code": 200, "message": "OK",
          "data": {
            "defect_id": 12, "analysis_id": 3, "type": "CRACK", "location": "거실 북쪽 벽",
            "severity": "HIGH", "area": 0.3, "estimated_cost": 80000, "description": "벽면 균열",
            "image_url": "https://example.com/defect.jpg",
            "region_3d": [{"x": 0.1, "y": 0.2, "z": 0.3}],
            "room_id": 5, "room_image_url": "https://example.com/room.jpg"
          }
        }
        """

        let detail = try decode(json)

        #expect(detail.defect.id == 12)
        #expect(detail.defect.analysisID == 3)
        #expect(detail.defect.type == .crack)
        #expect(detail.defect.severity == .high)
        #expect(detail.defect.repairCost == 80000)
        #expect(detail.defect.region3d.count == 1)
        #expect(detail.roomId == 5)
        #expect(detail.roomImageURL == "https://example.com/room.jpg")
    }

    @Test func room_image_url이_null이면_nil로_디코딩한다() throws {
        let json = """
        {
          "success": true, "code": 200, "message": "OK",
          "data": {
            "defect_id": 1, "analysis_id": 1, "type": "STAIN", "location": "천장",
            "severity": "LOW", "area": 0.1, "estimated_cost": 10000, "description": "얼룩",
            "image_url": null, "region_3d": [], "room_id": 2, "room_image_url": null
          }
        }
        """

        let detail = try decode(json)

        #expect(detail.defect.imageURL == nil)
        #expect(detail.roomImageURL == nil)
        #expect(detail.roomId == 2)
    }

    @Test func room_id가_없으면_디코딩에_실패한다() {
        let json = """
        {
          "success": true, "code": 200, "message": "OK",
          "data": {
            "defect_id": 1, "analysis_id": 1, "type": "STAIN", "location": "천장",
            "severity": "LOW", "area": 0.1, "estimated_cost": 10000, "description": "얼룩"
          }
        }
        """

        #expect(throws: DecodingError.self) { try decode(json) }
    }

    @Test func 서버_에러_응답은_DEFECT_001_코드로_매핑된다() {
        let json = """
        { "success": false, "code": 404, "message": "존재하지 않는 하자", "error": { "code": "DEFECT_001" } }
        """

        let error = #expect(throws: RepositoryError.self) { try decode(json) }
        #expect(error?.serverErrorCode == .defectNotFound)
    }
}
