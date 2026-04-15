//
//  FirestoreService.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 05.12.2025.
//


import Foundation
import FirebaseFirestore

@MainActor
class FirestoreService {
    
    private let db = Firestore.firestore()
    
    func loadQuestions(category: String, difficulty: Difficulty) async throws -> [QuizItem] {
        var query: Query = db.collection("questions")
        
        if category != QuestionCategory.alle.rawValue {
            query = query.whereField("category", isEqualTo: category)
        }
        
        query = query.whereField("difficulty", isEqualTo: difficulty.rawValue)
        
        let snapshot = try await query.getDocuments()
        
        return try snapshot.documents.compactMap {
            try $0.data(as: QuizItem.self)
        }
    }
    
    func loadAllQuestions() async throws -> [QuizItem] {
        let snapshot = try await db.collection("questions").getDocuments()
        
        return try snapshot.documents.compactMap {
            try $0.data(as: QuizItem.self)
        }
    }
}
