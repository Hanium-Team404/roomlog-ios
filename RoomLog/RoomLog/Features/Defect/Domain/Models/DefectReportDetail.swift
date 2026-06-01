//
//  DefectReportDetail.swift
//  
//
//  Created by 송민교 on 4/12/26.
//
import Foundation

struct DefectReportDetail: Hashable {
    let id: Int
    let imageURL: String?
    let type: DefectType
    let severity: Severity
    let description: String
    let repairCost: Int
    let defectArea: Double
    let location: String
    let discoveredDate: Date?
    let memo: String?
    let x: Float?
    let y: Float?
    let z: Float?
    let region3d: [DefectPoint3D]
}

struct DefectPoint3D: Hashable {
    let x: Float
    let y: Float
    let z: Float
}

enum DefectType: Hashable {
    case scratch, crack, peeling, stain, breakage

    init(rawString: String) {
        switch rawString.uppercased() {
        case "SCRATCH": self = .scratch
        case "CRACK": self = .crack
        case "PEELING": self = .peeling
        case "STAIN": self = .stain
        case "BREAKAGE": self = .breakage
        default: self = .scratch
        }
    }

    var serverValue: String {
        switch self {
        case .scratch: return "SCRATCH"
        case .crack: return "CRACK"
        case .peeling: return "PEELING"
        case .stain: return "STAIN"
        case .breakage: return "BREAKAGE"
        }
    }

    var displayName: String {
        switch self {
        case .scratch: return "긁힘"
        case .crack: return "균열"
        case .peeling: return "박리"
        case .stain: return "얼룩"
        case .breakage: return "파손"
        }
    }
}

enum Severity: Hashable {
    case high, medium, low

    init(rawString: String) {
        switch rawString.uppercased() {
        case "HIGH": self = .high
        case "MEDIUM": self = .medium
        default: self = .low
        }
    }

    var rank: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
