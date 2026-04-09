//
//  FetchHomeDataUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation

/// 홈 화면 진입 시 보여줄 메인 방 및 스캔한 방 리스트 조회 UseCaseProtocol
protocol FetchHomeDataUseCaseProtocol {
    func execute() async throws -> HomeData
}
