//
//  NavigationRoutingView.swift
//  Projects
//
//  Created by 김도연 on 3/26/26.
//

import SwiftUI

struct NavigationRoutingView: View {
    @Environment(\.di) var di: DIContainer
    
    let destination: NavigationDestination
    
    var body: some View {
        switch destination {
        case .auth(let auth):
            authView(auth)
        case .home(let home):
            homeView(home)
        case .defect(let defect):
            defectView(defect)
        case .myPage(let myPage):
            myPageView(myPage)
        }
    }
}

// MARK: - Route Detail Views

private extension NavigationRoutingView {
    @ViewBuilder
    func authView(_ route: NavigationDestination.Auth) -> some View {
        switch route {
        case .signup:
            SignUpView()
        }
    }
    
    @ViewBuilder
    func homeView(_ route: NavigationDestination.Home) -> some View {
        let provider = di.resolve(HomeUseCaseProvider.self)
        switch route {
        case .roomList(let houseId, let houseName):
            RoomListView(houseId: houseId, houseName: houseName, provider: provider)
        case .roomDetail(let roomId):
            RoomDetailView(
                roomId: roomId,
                provider: provider,
                scanRepository: di.resolve(ScanRepositoryProtocol.self)
            )
        case .scan(let houseId, let scanType):
            let pathStore = di.resolve(PathStore.self)
            ScanView(
                houseId: houseId,
                scanType: scanType,
                processingManager: di.resolve(ScanProcessingManager.self),
                onStartConversion: {
                    _ = pathStore.homePath.popLast()
                }
            )
        case .plyPreview(let fileURL, let scanId, let houseId):
            ScanPreviewView(fileURL: fileURL, scanId: scanId, houseId: houseId)
        case .houseList:
            HouseListView(provider: provider)
        }
    }
    
    @ViewBuilder
    func defectView(_ route: NavigationDestination.Defect) -> some View {
        switch route {
        case .mainView:
            ViewerView()
        case .defectList:
            DefectListView()
        case .defectListMain(let roomId):
            DefectView(roomId: roomId, provider: di.resolve(DefectUseCaseProvider.self))
        case .defectAllList(let roomId, let roomName, let defects):
            DefectAllListView(roomId: roomId, roomName: roomName, defects: defects)
        case .defectListDetail(let defect, let roomId, let roomImageURL):
            DefectDetailView(defect: defect, roomId: roomId, roomImageURL: roomImageURL)
        case .repairShopList(let roomId, let defect):
            RepairShopListView(roomId: roomId, defect: defect, provider: di.resolve(EstimateUseCaseProvider.self))
        case .repairHistory(let roomId):
            RepairHistoryView(roomId: roomId, provider: di.resolve(EstimateUseCaseProvider.self))
        }
    }
    
    @ViewBuilder
    func myPageView(_ route: NavigationDestination.MyPage) -> some View {
        switch route {
        case .test:
            Text("myPage")
        }
    }
}
