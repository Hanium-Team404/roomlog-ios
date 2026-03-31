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
        case test
    }
    
    enum MyPage: Hashable {
        case test
    }
    
    case auth(Auth)
    case home(Home)
    case defect(Defect)
    case myPage(MyPage)
}
