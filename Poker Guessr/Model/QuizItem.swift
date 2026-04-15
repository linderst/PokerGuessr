//
//  QuizItem.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 02.12.2025.
//

import Foundation
import FirebaseFirestore

struct QuizItem: Identifiable, Codable {
    @DocumentID var id: String?
    let question: String
    let answer: String? // Optional -> Legacy compatibility
    
    // Neues masseinheitenbasiertes System
    let answerBaseValue: Double?
    let dimension: QuizDimension?
    let defaultUnitText: String?
    
    let category: String
    let tips: [String]
    let difficulty: Difficulty
}
