//
//  UploadScanUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 4/12/26.
//

import Foundation

protocol UploadScanUseCaseProtocol {
    /// 스캔 데이터셋 디렉토리를 zip으로 압축 후 서버에 업로드합니다.
    /// - Parameters:
    ///   - datasetDirectory: DatasetEncoder가 저장한 데이터셋 폴더 URL
    ///   - roomId: 업로드할 방 ID
    func execute(datasetDirectory: URL, roomId: Int) async throws -> ScanResult
}
