import Foundation

/// Berechnet die Rangliste basierend auf Spieler-Tipps und der korrekten Antwort.
struct RankingService {
    
    struct RankedResult {
        let player: Player
        let diff: Double
        let guess: Double
        let points: Int
    }
    
    /// Berechnet die sortierte Rangliste für eine Frage.
    static func calculateRanking(
        for question: QuizItem,
        players: [Player],
        guesses: [UUID: String],
        unitSelections: [UUID: Int]
    ) -> [RankedResult]? {
        
        let targetBaseValue: Double
        if let baseVal = question.answerBaseValue {
            targetBaseValue = baseVal
        } else if let answerStr = question.answer, let extracted = answerStr.extractFirstDouble() {
            targetBaseValue = extracted
        } else {
            return nil
        }
        
        let dimension = question.dimension ?? .none
        var results: [(player: Player, diff: Double, guess: Double)] = []
        
        for player in players {
            if let guessStr = guesses[player.id],
               let rawGuessNum = guessStr.extractFirstDouble() {
                
                let selectedIdx = unitSelections[player.id] ?? dimension.defaultIndex
                let multiplier: Double
                if selectedIdx >= 0 && selectedIdx < dimension.options.count {
                    multiplier = dimension.options[selectedIdx].multiplier
                } else {
                    multiplier = 1.0
                }
                
                let finalGuessValue = rawGuessNum * multiplier
                let diff = abs(finalGuessValue - targetBaseValue)
                results.append((player: player, diff: diff, guess: finalGuessValue))
            } else {
                results.append((player: player, diff: Double.greatestFiniteMagnitude, guess: .nan))
            }
        }
        
        results.sort { $0.diff < $1.diff }
        
        return results.enumerated().map { index, res in
            var earnedPoints = 0
            if res.diff != Double.greatestFiniteMagnitude {
                if index == 0 { earnedPoints = 3 }
                else if index == 1 { earnedPoints = 2 }
                else if index == 2 { earnedPoints = 1 }
            }
            return RankedResult(
                player: res.player,
                diff: res.diff,
                guess: res.guess,
                points: earnedPoints
            )
        }
    }
}
