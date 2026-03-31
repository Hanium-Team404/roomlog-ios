//
//  PathStore.swift
//  Projects
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
}
