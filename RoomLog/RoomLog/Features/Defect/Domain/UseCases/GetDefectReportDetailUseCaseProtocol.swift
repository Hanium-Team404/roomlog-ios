//
//  GetDefectReportDetailUseCaseProtocol.swift
//
//
//  Created by 송민교 on 4/12/26.
//

import Foundation

/// 하자 id로 상세 정보를 조회하는 UseCaseProtocol (방 하자 목록을 거치지 않는 진입용)
protocol GetDefectReportDetailUseCaseProtocol {
    func execute(defectId: Int) async throws -> DefectDetail
}
