//
//  HomeState.swift
//  RoomLog
//
//  Created by 김도연 on 5/9/26.
//

import Foundation
import Observation

@Observable
final class HomeState {
    var hasHouses: Bool = false
    var selectedHouse: House?
    var recenterMapTrigger: Int = 0
}
