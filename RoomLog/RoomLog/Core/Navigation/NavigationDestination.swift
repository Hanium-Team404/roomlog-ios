//
//  NavigationDestination.swift
//  RoomLog
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
        case scan(houseId: Int)
        case scanPreview(fileURL: URL, scanId: Int, houseId: Int)
        case houseList
    }
    
    enum Defect: Hashable {
        /// 하자점검, 내방비교
        case mainView
        /// 하자점검 case
        case defectList(houseId: Int)
        case defectListMain(roomId: Int)
        case defectAllList(roomName: String, defects: [DefectReportDetail])
        /// 하자 상세. id만 싣고 화면이 직접 조회하므로 목록·챗봇·알림 어디서든 같은 목적지로 연다
        case defectDetail(defectId: Int, scrollsToSelfRepair: Bool = false)
        case repairShopList(roomId: Int, defect: DefectReportDetail)
        case repairHistory(roomId: Int)
        
        /// 내방비교 case
        case comparisonHistory
        case comparisonSelect
        case comparisonResult(moveInRoomId: Int, moveOutRoomId: Int, analysisID: Int? = nil)
    }
    
    enum MyPage: Hashable {
        case test
    }
    
    case auth(Auth)
    case home(Home)
    case defect(Defect)
    case myPage(MyPage)
    case chatbot
}
