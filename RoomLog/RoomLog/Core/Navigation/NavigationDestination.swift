//
//  NavigationDestination.swift
//  Projects
//
//  Created by 김도연 on 3/26/26.
//

import Foundation

enum NavigationDestination: Hashable {
    enum Auth: Hashable {
        case signup
    }
    
    enum Home: Hashable {
        case roomList(houseId: Int)
        case roomDetail(roomId: Int)
        case scan
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
