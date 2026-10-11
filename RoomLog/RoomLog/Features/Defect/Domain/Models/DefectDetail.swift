//
//  DefectDetail.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/11/26.
//

import Foundation

/// 하자 id 단건 조회 결과.
/// 상세 화면이 요구하는 방 정보를 함께 담아, 방 하자 목록을 거치지 않고도 `DefectDetailView`를 열 수 있게 한다
struct DefectDetail: Hashable {
    let defect: DefectReportDetail
    /// 추천 업체 조회 등 방 단위 기능에 사용
    let roomId: Int
    /// 하자 `imageURL`이 없을 때 대체로 쓰는 방 썸네일
    let roomImageURL: String?
}
