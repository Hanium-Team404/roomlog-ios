//
//  PathStore.swift
//  RoomLog
//
//  Created by 김도연 on 3/26/26.
//

import Foundation

@Observable
final class PathStore {
    /// 홈 탭 네비게이션 경로
    var homePath: [NavigationDestination] = []
    /// 하자 및 비교 탭 네비게이션 경로
    var defectPath: [NavigationDestination] = []
    /// 마이페이지 탭 네비게이션 경로
    var mypagePath: [NavigationDestination] = []
    /// 완료 알림을 눌러 스캔 상태 시트를 열 집. 메인 화면이 처리할 때까지 남겨
    /// 앱이 꺼진 상태에서 알림으로 열린 경우(스플래시·로그인 확인 이후)에도 이동한다
    var scanStatusRequest: Int?
}
