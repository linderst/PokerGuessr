//
//  QuizDimension.swift
//  Poker Guessr
//

import Foundation

enum QuizDimension: String, Codable, CaseIterable {
    case weight
    case length
    case time
    case volume
    case count
    case currency
    case none
    
    struct UnitOption {
        let label: String
        let multiplier: Double
    }
    
    var options: [UnitOption] {
        switch self {
        case .weight:
            return [
                UnitOption(label: "mg", multiplier: 0.000_001),
                UnitOption(label: "g", multiplier: 0.001),
                UnitOption(label: "kg", multiplier: 1.0),
                UnitOption(label: "t", multiplier: 1000.0)
            ]
        case .length:
            return [
                UnitOption(label: "mm", multiplier: 0.001),
                UnitOption(label: "cm", multiplier: 0.01),
                UnitOption(label: "m", multiplier: 1.0),
                UnitOption(label: "km", multiplier: 1000.0)
            ]
        case .time:
            return [
                UnitOption(label: "Sek.", multiplier: 1.0),
                UnitOption(label: "Min.", multiplier: 60.0),
                UnitOption(label: "Std.", multiplier: 3600.0),
                UnitOption(label: "Tage", multiplier: 86400.0),
                UnitOption(label: "Jahre", multiplier: 31536000.0)
            ]
        case .volume:
            return [
                UnitOption(label: "ml", multiplier: 0.001),
                UnitOption(label: "L", multiplier: 1.0),
                UnitOption(label: "m³", multiplier: 1000.0)
            ]
        case .count:
            return [
                UnitOption(label: "x1", multiplier: 1.0),
                UnitOption(label: "Tausend", multiplier: 1_000.0),
                UnitOption(label: "Mio.", multiplier: 1_000_000.0),
                UnitOption(label: "Mrd.", multiplier: 1_000_000_000.0)
            ]
        case .currency:
            return [
                UnitOption(label: "x1", multiplier: 1.0),
                UnitOption(label: "Tausend", multiplier: 1_000.0),
                UnitOption(label: "Mio.", multiplier: 1_000_000.0),
                UnitOption(label: "Mrd.", multiplier: 1_000_000_000.0)
            ]
        case .none:
            return [
                UnitOption(label: "", multiplier: 1.0)
            ]
        }
    }
    
    var defaultIndex: Int {
        switch self {
        case .weight: return 2 // kg
        case .length: return 2 // m
        case .time: return 1 // Min.
        case .volume: return 1 // L
        case .count: return 0 // x1
        case .currency: return 0 // x1
        case .none: return 0
        }
    }
}
