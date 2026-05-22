//
//  ComparisonScan.swift
//  RoomLog
//
//  Created by minkyo on 5/21/26.
//

import Foundation

struct ComparisonScan: Hashable, Identifiable {
    let id: Int
    let roomName: String
    let scanDate: Date
    let thumbnailURL: String?
    let scanType: ScanType // "IN" or "OUT"
}

public enum ScanType: String, Codable {
    case moveIn = "IN"
    case moveOut = "OUT"
}
