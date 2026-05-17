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
        case roomList(houseId: Int, houseName: String)
        case roomDetail(roomId: Int)
        case scan(houseId: Int, scanType: String)
        case plyPreview(fileURL: URL, scanId: Int, houseId: Int)
        case houseList
    }
    
    enum Defect: Hashable {
        case mainView // 하자점검, 내방비교
        case defectList
        case defectListMain(roomId: Int)
        case defectListDetail(defect: DefectReportDetail, roomId: Int, roomImageURL: String?)
        case repairShopList(roomId: Int, defect: DefectReportDetail)
        case repairHistory
    }
    
    enum MyPage: Hashable {
        case test
    }
    
    case auth(Auth)
    case home(Home)
    case defect(Defect)
    case myPage(MyPage)
}
