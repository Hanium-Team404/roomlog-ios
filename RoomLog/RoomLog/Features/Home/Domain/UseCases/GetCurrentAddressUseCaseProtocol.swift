//
//  GetCurrentAddressUseCaseProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 8/16/26.
//

import Foundation

protocol GetCurrentAddressUseCaseProtocol {
    /// 현재 위치 기반 주소 스트림을 반환한다. 정확도가 개선될 때마다 주소를 방출한다.
    func execute() -> AsyncStream<String>
}
