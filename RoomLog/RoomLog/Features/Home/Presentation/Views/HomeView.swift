//
//  HomeView.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.di) private var di

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    var body: some View {
        ZStack {
            // 맵이 베이스
            HouseMapView { house in
                pathStore.homePath.append(.home(.roomList(houseId: house.houseId)))
            }
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
