//
//  GameViewModel.swift
//  Poker Guessr
//

import Foundation
import Combine
import OSLog
import FirebaseFirestore

@MainActor
class GameViewModel: ObservableObject {

    private static let logger = Logger(subsystem: "com.stefanlinder.pokerguessr", category: "Game")
    
    // MARK: - Published State
    @Published var allQuestions: [QuizItem] = []
    @Published var currentQuestion: QuizItem?
    @Published var quizState: QuizState = .question
    @Published var currentIndex: Int = 0
    @Published var currentRound: Int = 1
    @Published var isOutOfQuestions: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Player State
    @Published var players: [Player] = []
    @Published var currentGuesses: [UUID: String] = [:]
    @Published var currentUnitSelections: [UUID: Int] = [:]
    @Published var currentRanking: [(player: Player, diff: Double, guess: Double, points: Int)] = []
    @Published var currentPlayerGuessIndex: Int = 0
    
    // MARK: - Configuration (immutable)
    let trackOverallScore: Bool
    let totalRounds: Int?
    let category: String
    let difficulty: Difficulty
    let persistentMode: Bool
    let tipsCount: Int
    let separateRanking: Bool
    
    // MARK: - Dependencies
    private let firestoreService: FirestoreService
    
    // MARK: - Initializer
    init(
        category: String,
        difficulty: Difficulty,
        persistentMode: Bool,
        totalRounds: Int? = nil,
        players: [Player] = [],
        trackOverallScore: Bool = false,
        tipsCount: Int = 3,
        separateRanking: Bool = false,
        firestoreService: FirestoreService? = nil
    ) {
        self.category = category
        self.difficulty = difficulty
        self.persistentMode = persistentMode
        self.totalRounds = totalRounds
        self.players = players
        self.trackOverallScore = trackOverallScore
        self.tipsCount = tipsCount
        self.separateRanking = separateRanking
        self.firestoreService = firestoreService ?? FirestoreService()
        
        Task {
            await loadQuestions()
            loadFirstQuestion()
        }
    }
    
    // MARK: - Data Loading
    
    func loadQuestions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let loaded = try await firestoreService.loadQuestions(category: category, difficulty: difficulty)
            self.allQuestions = loaded
            self.isOutOfQuestions = loaded.isEmpty
        } catch {
            Self.logger.error("Fehler beim Laden aus Firestore: \(error.localizedDescription, privacy: .public)")
            self.errorMessage = "Fehler beim Laden der Fragen. Bitte überprüfe deine Internetverbindung."
            self.showError = true
            self.allQuestions = []
            self.isOutOfQuestions = true
        }
    }
    
    func loadFirstQuestion() {
        currentRound = 1
        guard !allQuestions.isEmpty else {
            isOutOfQuestions = true
            currentQuestion = nil
            return
        }
        
        currentIndex = 0
        currentQuestion = allQuestions[currentIndex]
        isOutOfQuestions = false
        resetUnitSelections()
        
        if !players.isEmpty {
            currentPlayerGuessIndex = 0
            quizState = .guessing
        } else {
            quizState = .question
        }
    }
    
    // MARK: - State Machine
    
    func nextState() {
        switch quizState {
        case .question:
            if !players.isEmpty {
                currentPlayerGuessIndex = 0
                quizState = .guessing
            } else {
                quizState = tipsCount == 0 ? .answer : .tip1
            }
        case .guessing:
            if currentPlayerGuessIndex < players.count - 1 {
                currentPlayerGuessIndex += 1
            } else {
                if tipsCount == 0 { triggerAnswer() }
                else { quizState = .tip1 }
            }
        case .tip1:
            if tipsCount == 1 { triggerAnswer() } else { quizState = .tip2 }
        case .tip2:
            if tipsCount == 2 { triggerAnswer() } else { quizState = .tip3 }
        case .tip3:
            triggerAnswer()
        case .answer:
            if separateRanking && !players.isEmpty {
                quizState = .ranking
            } else {
                nextQuestion()
            }
        case .ranking:
            nextQuestion()
        }
    }
    
    func stepBack() {
        switch quizState {
        case .question:
            break
        case .guessing:
            if currentPlayerGuessIndex > 0 {
                currentPlayerGuessIndex -= 1
            } else {
                quizState = .question
            }
        case .tip1:
            if players.isEmpty {
                quizState = .question
            } else {
                quizState = .guessing
                currentPlayerGuessIndex = players.count - 1
            }
        case .tip2:
            quizState = .tip1
        case .tip3:
            quizState = .tip2
        case .answer:
            if tipsCount == 3 { quizState = .tip3 }
            else if tipsCount == 2 { quizState = .tip2 }
            else if tipsCount == 1 { quizState = .tip1 }
            else { quizState = players.isEmpty ? .question : .guessing }
        case .ranking:
            quizState = .answer
        }
    }
    
    func skip() {
        nextQuestion()
    }
    
    // MARK: - Derived Properties (von GameView hierher verschoben)
    
    var stepTitle: String {
        switch quizState {
        case .question, .guessing: return "Frage lesen"
        case .tip1:     return "Tipp 1"
        case .tip2:     return "Tipp 2"
        case .tip3:     return "Tipp 3"
        case .answer:   return "Auflösung"
        case .ranking:  return "Rangliste"
        }
    }
    
    var currentStepIndex: Int {
        switch quizState {
        case .question, .guessing: return 0
        case .tip1:     return 1
        case .tip2:     return 2
        case .tip3:     return 3
        case .answer:   return 1 + tipsCount
        case .ranking:  return 2 + tipsCount
        }
    }
    
    var totalSteps: Int {
        let hasRankingRound = separateRanking && !players.isEmpty
        return tipsCount + 2 + (hasRankingRound ? 1 : 0)
    }
    
    var primaryButtonTitle: String {
        switch quizState {
        case .question:
            return players.isEmpty ? "Auflösung anzeigen" : "Tipps abgeben"
        case .guessing:
            return "Tipp speichern (\(currentPlayerGuessIndex + 1)/\(players.count))"
        case .tip1:
            return tipsCount == 1 ? "Lösung anzeigen" : "Tipp 2 anzeigen"
        case .tip2:
            return tipsCount == 2 ? "Lösung anzeigen" : "Tipp 3 anzeigen"
        case .tip3:
            return "Lösung anzeigen"
        case .answer:
            return separateRanking && !players.isEmpty ? "Rangliste anzeigen" : "Nächste Frage"
        case .ranking:
            return "Nächste Frage"
        }
    }
    
    var isPrimaryDisabled: Bool {
        guard quizState == .guessing else { return false }
        let currentPlayer = players[currentPlayerGuessIndex]
        guard let guess = currentGuesses[currentPlayer.id] else { return true }
        let normalized = guess.replacingOccurrences(of: ",", with: ".")
        return guess.trimmingCharacters(in: .whitespaces).isEmpty || Double(normalized) == nil
    }
    
    var canStepBack: Bool {
        quizState != .question && !(quizState == .guessing && currentPlayerGuessIndex == 0)
    }
    
    var canSkip: Bool {
        quizState == .question || quizState == .guessing
    }
    
    func visibleTips() -> [String] {
        guard let tips = currentQuestion?.tips else { return [] }
        switch quizState {
        case .question, .guessing:
            return []
        case .tip1:
            return [tips[0]]
        case .tip2:
            return persistentMode ? [tips[0], tips[1]] : [tips[1]]
        case .tip3:
            return persistentMode ? [tips[0], tips[1], tips[2]] : [tips[2]]
        case .answer, .ranking:
            let shown = Array(tips.prefix(min(tipsCount, tips.count)))
            return persistentMode ? shown : []
        }
    }
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = "'"
        return formatter
    }()
    
    /// Formatiert eine Zahl mit Tausender-Trennzeichen.
    func formatNumber(_ value: Double) -> String {
        return Self.numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    // MARK: - Private Helpers
    
    private func triggerAnswer() {
        if !players.isEmpty {
            calculateRanking()
        }
        quizState = .answer
    }
    
    private func nextQuestion() {
        currentGuesses.removeAll()
        currentUnitSelections.removeAll()
        currentRanking.removeAll()
        currentPlayerGuessIndex = 0
        
        if quizState == .answer || quizState == .ranking {
            currentRound += 1
        }
        
        currentIndex += 1
        if currentIndex >= allQuestions.count {
            currentQuestion = nil
            isOutOfQuestions = true
            return
        }
        
        currentQuestion = allQuestions[currentIndex]
        resetUnitSelections()
        
        if !players.isEmpty {
            quizState = .guessing
        } else {
            quizState = .question
        }
    }
    
    private func calculateRanking() {
        guard let question = currentQuestion else { return }
        
        guard let results = RankingService.calculateRanking(
            for: question,
            players: players,
            guesses: currentGuesses,
            unitSelections: currentUnitSelections
        ) else { return }
        
        // Punkte auf Spieler anwenden
        if trackOverallScore {
            for result in results {
                if let playerIndex = players.firstIndex(where: { $0.id == result.player.id }) {
                    players[playerIndex].score += result.points
                }
            }
        }
        
        self.currentRanking = results.map { ($0.player, $0.diff, $0.guess, $0.points) }
    }
    
    private func resetUnitSelections() {
        let defaultIdx = currentQuestion?.dimension?.defaultIndex ?? 0
        for p in players {
            currentUnitSelections[p.id] = defaultIdx
        }
    }
}
