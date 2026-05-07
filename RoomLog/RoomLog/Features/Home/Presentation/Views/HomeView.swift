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

    init(provider: HomeUseCaseProvider) {
        self._viewModel = .init(
            wrappedValue: HomeViewModel(provider: provider)
        )
    }

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    var body: some View {
        HouseMapView(houses: viewModel.houses) { house in
            pathStore.homePath.append(.home(.roomList(houseId: house.houseId)))
        }
        .task {
            await viewModel.fetchHouses()
        }
        .toolbar {
            ToolbarItem(placement: .title) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128)
                    .padding(.top)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    print("plus")
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
