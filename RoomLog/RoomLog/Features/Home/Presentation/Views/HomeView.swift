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
        HouseMapView(
            houses: viewModel.houses,
            mainHouseId: viewModel.mainHouse?.houseId,
            namespace: houseNamespace,
            recenterTrigger: homeState.recenterMapTrigger
        ) { house in
            homeState.selectedHouse = house
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
            ToolbarItem(placement: .principal) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
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
                    viewModel.showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .chatbotEntryButton {
            pathStore.homePath.append(.chatbot)
        }
        .tint(.accent)
        .sheet(isPresented: $viewModel.showCreateSheet) {
            HouseSheet(addressUpdates: viewModel.currentAddressUpdates) { name, address, houseColor, floorColor in
                try await viewModel.createHouse(
                    name: name, address: address,
                    houseColor: houseColor, floorColor: floorColor
                )
                homeState.hasHouses = !viewModel.houses.isEmpty
            }
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
