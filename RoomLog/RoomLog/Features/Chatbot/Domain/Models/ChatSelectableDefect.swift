//
//  ChatSelectableDefect.swift
//  RoomLog
//
//  Created by Doyeon Kim on 8/31/26.
//

import Foundation

/// 챗봇 하자 선택 sheet에 노출되는 대표 집의 하자 (C04)
struct ChatSelectableDefect: Identifiable, Hashable {
    let id: Int
    let type: DefectType
    let severity: Severity
    /// 방 안에서의 위치 상세 (예: 벽면 북서부)
    let location: String
    /// 하자가 속한 방 이름 (예: 거실)
    let roomName: String
    let imageURL: String?
}
