//
//  APIErrorResponse.swift
//  RoomLog
//
//  Created by Doyeon Kim on 10/12/26.
//

import Foundation

/// 실패 응답은 성공 여부나 결과 DTO 없이 오류 정보만 읽는다.
nonisolated struct APIErrorResponse: Decodable, Sendable {
    let message: String?
    let error: APIErrorBody?
}
