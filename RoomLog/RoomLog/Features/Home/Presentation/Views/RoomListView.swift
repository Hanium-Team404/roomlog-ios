//
//  RoomListView.swift
//  RoomLog
//
//  Created by 김도연 on 5/4/26.
//

import SwiftUI

struct RoomListView: View {
    let houseId: Int
    
    var body: some View {
        VStack {
            Text("\(houseId)")
        }
    }
}
