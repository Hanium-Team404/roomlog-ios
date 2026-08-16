//
//  CurrentAddressProviderProtocol.swift
//  RoomLog
//
//  Created by 김도연 on 8/16/26.
//

import Foundation

/// 현재 위치 기반 주소 스트림을 제공하는 인터페이스.
/// 정확도가 개선될 때마다 주소 문자열을 방출하고, 획득 불가 시 아무것도 방출하지 않고 종료한다.
protocol CurrentAddressProviderProtocol {
    func addressUpdates() -> AsyncStream<String>
}
