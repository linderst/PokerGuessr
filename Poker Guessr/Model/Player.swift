//
//  Player.swift
//  Poker Guessr
//

import Foundation

struct Player: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var score: Int = 0
}
