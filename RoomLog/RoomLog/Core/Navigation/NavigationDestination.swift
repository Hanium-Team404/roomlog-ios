//
//  NavigationDestination.swift
//  Projects
//
//  Created by 김도연 on 3/26/26.
//

import Foundation

enum NavigationDestination: Hashable {
    enum Auth: Hashable {
        case test
    }
    
    enum Home: Hashable {
        case test
    }
    
    enum Defect: Hashable {
        case mainView // 하자점검, 내방비교
        case defectList
        case defectListMain(roomId: Int)
        case defectListDetail
    }
    
    enum MyPage: Hashable {
        case test
    }
    
    case auth(Auth)
    case home(Home)
    case defect(Defect)
    case myPage(MyPage)
}
