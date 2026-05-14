//
//  HomeView.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.di) private var di
    @State private var viewModel: HomeViewModel
    @Namespace private var houseNamespace

    init(provider: HomeUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: HomeViewModel(provider: provider)
        )
    }

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    private var homeState: HomeState {
        di.resolve(HomeState.self)
    }

    var body: some View {
        HouseMapView(houses: viewModel.houses, mainHouseId: viewModel.mainHouse?.houseId, namespace: houseNamespace) { house in
            pathStore.homePath.append(.home(.roomList(houseId: house.houseId, houseName: house.name)))
        }
        .navigationDestination(for: NavigationDestination.self) { dest in
            if case .home(.roomList) = dest {
                NavigationRoutingView(destination: dest)
                    .navigationTransition(.zoom(sourceID: sourceID(for: dest), in: houseNamespace))
            } else {
                NavigationRoutingView(destination: dest)
            }
        }
        .task {
            await viewModel.fetchHouses()
            homeState.hasHouses = !viewModel.houses.isEmpty
        }
        .toolbar {
            ToolbarItem(placement: .title) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128)
                    .padding(.top)
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    pathStore.homePath.append(.home(.houseList))
                } label: {
                    Image(.houseList)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showAddHouseAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .tint(.accent)
        .alert("어떤 이름으로 저장할까요?", isPresented: $viewModel.showAddHouseAlert) {
            TextField("예: 망고의 집", text: $viewModel.newHouseName)
            
            Button("취소", role: .cancel) {
                viewModel.newHouseName = ""
            }
            Button("만들기") {
                Task {
                    await viewModel.createHouse()
                    homeState.hasHouses = !viewModel.houses.isEmpty
                }
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private func sourceID(for destination: NavigationDestination) -> Int {
        switch destination {
        case .home(.roomList(let houseId, _)):
            return houseId
        default:
            return 0
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(
            provider: DIContainer.configured().resolve(HomeUseCaseProvider.self)
        )
    }
    .environment(\.di, .configured())
}
