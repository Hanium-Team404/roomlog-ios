//
//  RoomLogTab.swift
//  RoomLog
//
//  Created by 김도연 on 3/31/26.
//

import SwiftUI


struct RoomLogTab: View {

    // MARK: - Property
    @State var isShowMyPage: Bool = false
    @State private var selectedTab: TabIdentifier = .home
    @State private var showViewerLockedToast: Bool = false
    @Environment(\.di) var di
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    private enum TabIdentifier: Hashable {
        case home, viewer, profile
    }

    // MARK: - Body
    var body: some View {
        let pathStore = di.resolve(PathStore.self)
        let homeState = di.resolve(HomeState.self)
        let _ = di.resolve(ScanProcessingManager.self)

        TabView(selection: $selectedTab) {
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
                NavigationStack {
                    MyPageView(provider: di.resolve(MyPageUseCaseProvider.self))
                }
            }
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
        .onChange(of: scenePhase) { _, newPhase in
            di.resolve(ScanProcessingManager.self).handleScenePhase(newPhase)
        }
    }
}

#Preview {
    RoomLogTab()
}
