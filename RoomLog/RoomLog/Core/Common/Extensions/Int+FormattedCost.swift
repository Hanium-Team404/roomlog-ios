//
//  Int+FormattedCost.swift
//  RoomLog
//
//  Created by minkyo on 6/3/26.
//

import Foundation

extension Int {
    var formattedCost: String {
        let manWon = self / 10000
        if manWon > 0 { return "\(manWon)만원" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return "\(f.string(from: NSNumber(value: self)) ?? "\(self)")원"
    }
}
