//
//  CurrentAddressProvider.swift
//  RoomLog
//
//  Created by 김도연 on 8/16/26.
//

import CoreLocation
import MapKit

/// 현재 위치를 도로명 수준의 주소 문자열로 변환하는 헬퍼.
/// 권한 거부·위치 획득 실패·역지오코딩 실패 시 아무것도 방출하지 않는다 (조용히 스킵).
struct CurrentAddressProvider {

    /// 위치 정확도가 개선될 때마다 주소를 방출하는 스트림.
    /// 첫 픽스(Wi-Fi/셀 추정, 수백 m 오차)로 즉시 한 번 방출해 빠르게 채우고,
    /// 정확도가 유의미하게 좋아진 픽스가 오면 갱신된 주소를 다시 방출한다.
    func addressUpdates() -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                defer { continuation.finish() }

                let session = CLServiceSession(authorization: .whenInUse)
                defer { session.invalidate() }

                let desiredAccuracy: CLLocationAccuracy = 50
                let maxFixCount = 8

                var lastGeocodedAccuracy: CLLocationAccuracy = .infinity
                var fixCount = 0
                do {
                    for try await update in CLLocationUpdate.liveUpdates() {
                        if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                            return
                        }
                        guard let location = update.location, location.horizontalAccuracy >= 0 else { continue }
                        fixCount += 1

                        // 목표 정확도 도달: 최종 주소로 갱신하고 종료
                        if location.horizontalAccuracy <= desiredAccuracy {
                            if let address = await reverseGeocode(location) {
                                continuation.yield(address)
                            }
                            return
                        }
                        // 정확도가 절반 이하로 좋아졌을 때만 중간 갱신 (지오코딩 요청 수 제한 대응)
                        if location.horizontalAccuracy < lastGeocodedAccuracy * 0.5 {
                            lastGeocodedAccuracy = location.horizontalAccuracy
                            if let address = await reverseGeocode(location) {
                                continuation.yield(address)
                            }
                        }
                        if fixCount >= maxFixCount { return }
                    }
                } catch {
                    return
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func reverseGeocode(_ location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        request.preferredLocale = Locale(identifier: "ko_KR")
        do {
            let mapItems = try await request.mapItems
            guard let representations = mapItems.first?.addressRepresentations,
                  let fullAddress = representations.fullAddress(includingRegion: false, singleLine: true)
            else { return nil }
            return fullAddress
                .replacing(/[,\s]+\d{5}\s*$/, with: "")
                .trimmingCharacters(in: .whitespaces)
        } catch {
            return nil
        }
    }
}
