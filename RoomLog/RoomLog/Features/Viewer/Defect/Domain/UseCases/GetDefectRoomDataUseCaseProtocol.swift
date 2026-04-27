//
//  GetDefectRoomDataUseCase.swift
//  
//
//  Created by 송민교 on 4/12/26.
//

import Foundation

/// 맨 처음 방 조회 UseCaseProtocol
protocol GetDefectRoomDataUseCaseProtocol {
    func execute() async throws -> [DefectRoomData]
}
