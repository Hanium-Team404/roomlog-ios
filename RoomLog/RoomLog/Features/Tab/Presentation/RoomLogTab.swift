//
//  RoomLogTab.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import SwiftUI


struct RoomLogTab: View {

    // MARK: - Property
    @State private var selectedTab: TabIdentifier = .home
    @State private var showViewerLockedToast: Bool = false
    @Environment(\.di) var di

    private enum TabIdentifier: Hashable {
        case home, viewer, profile
    }

    // MARK: - Body
    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        let homeState = di.resolve(HomeState.self)

        let tabSelection = Binding<TabIdentifier>(
            get: { selectedTab },
            set: { newValue in
                if newValue == .home && selectedTab == .home {
                    homeState.recenterMapTrigger += 1
                }
                selectedTab = newValue
            }
        )

        TabView(selection: tabSelection) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack(path: Bindable(pathStore).homePath) {
                    HomeView(provider: di.resolve(HomeUseCaseProvider.self))
                }
            }
            Tab("Viewer", systemImage: "magnifyingglass", value: .viewer) {
                NavigationStack(path: Bindable(pathStore).defectPath) {
                    ViewerView()
                        .navigationDestination(for: NavigationDestination.self) {
                            NavigationRoutingView(destination: $0)
                        }
                }
            }
            Tab("Profile", systemImage: "person.fill", value: .profile) {
                NavigationStack(path: Bindable(pathStore).mypagePath) {
                    MyPageView(provider: di.resolve(MyPageUseCaseProvider.self))
                        .navigationDestination(for: NavigationDestination.self) {
                            NavigationRoutingView(destination: $0)
                        }
                }
            }
        }
        .task {
            // 메인 진입 시 매니저를 생성해 중단된 스캔 복구(configure → resumeRestoredWork)를 시작한다
            _ = di.resolve(ScanProcessingManager.self)
            // 앱이 꺼진 상태에서 알림으로 열렸다면 복구를 시작한 뒤 요청된 화면으로 이동한다
            openRequestedScanStatus(pathStore: pathStore)
        }
        .onChange(of: pathStore.scanStatusRequest) {
            openRequestedScanStatus(pathStore: pathStore)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .viewer && !homeState.hasHouses {
                selectedTab = .home
                showViewerLockedToast = true
            }
        }
        .overlay(alignment: .top) {
            if showViewerLockedToast {
                ToastView {
                    HStack(spacing: 0) {
                        Text("집을 추가한 뒤 ")
                            .foregroundStyle(.neutral600)
                        Text("Viewer")
                            .foregroundStyle(.dustyBlue)
                        Text("를 사용하실 수 있습니다")
                            .foregroundStyle(.neutral600)
                    }
                    .font(.medium, 14)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 24)
                .safeAreaPadding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task {
                    try? await Task.sleep(for: .seconds(2.5))
                    withAnimation {
                        showViewerLockedToast = false
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showViewerLockedToast)
    }

    /// 완료 알림으로 요청된 집의 방 목록으로 이동한다. 상태 시트는 방 목록이 요청을 확인하고 연다
    private func openRequestedScanStatus(pathStore: PathStore) {
        guard let houseId = pathStore.scanStatusRequest else { return }
        selectedTab = .home
        if case .home(.roomList(let shownHouseId, _)) = pathStore.homePath.last, shownHouseId == houseId {
            return
        }
        // 집 이름은 방 목록 조회 응답이 채운다
        pathStore.homePath = [.home(.roomList(houseId: houseId, houseName: ""))]
    }
}

#Preview {
    RoomLogTab()
}
