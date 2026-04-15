//
//  Difficulty.swift
//  Poker Guessr
//

import Foundation

enum Difficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "Leicht"
        case .medium: return "Mittel"
        case .hard: return "Schwer"
        }
    }
}
