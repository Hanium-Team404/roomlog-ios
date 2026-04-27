//
//  GetDefectReportUseCaseProtocol.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation

/// 선택한 방의 하자 보고서 조회 UseCaseProtocol
protocol GetDefectReportUseCaseProtocol {
    func execute(roomId: Int) async throws -> DefectReport
}
