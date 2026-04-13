//
//  GetDefectReportDetailUseCaseProtocol.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation

/// 선택한 방의 하자 상세 정보 조회 UseCaseProtocol
protocol GetDefectReportDetailUseCaseProtocol {
    func execute(roomId: Int, reportId: Int) async throws -> DefectReportDetail
}
