//
//  EstimateDTO.swift
//  RoomLog
//
//  Created by 송민교 on 5/10/26.
//

import Foundation

struct RepairShop: Identifiable, Hashable {
    let externalId: String
    let name: String
    let phone: String
    let address: String
    let latitude: Double
    let longitude: Double
    let imageURL: String?
    let distance: Double

    var id: String { externalId }
}
