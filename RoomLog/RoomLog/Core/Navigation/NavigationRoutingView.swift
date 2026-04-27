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
        case .test:
            Text("Auth Test View")
        }
    }
    
    @ViewBuilder
    func homeView(_ route: NavigationDestination.Home) -> some View {
        switch route {
        case .test:
            Text("home")
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
            DefectView(roomId: roomId)
        case .defectListDetail:
            Text("하자점검 목록 디테일 - TODO")
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
