import SwiftUI
import Foundation

struct GameView: View {
    
    let category: String
    let selectedDifficulty: Difficulty
    let persistentMode: Bool
    let totalRounds: Int?          // nil = unbegrenzt
    let tipsCount: Int
    let separateRanking: Bool
    
    @StateObject var vm: GameViewModel
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var haptics: HapticsManager
    
    @State private var showExitAlert = false
    @State private var currentRound: Int = 1
    
    // Animation States
    @State private var animateQuestion = false
    @State private var questionID = UUID()
    
    @FocusState private var isInputFocused: Bool
    
    init(
        category: String,
        selectedDifficulty: Difficulty,
        persistentMode: Bool,
        totalRounds: Int? = nil,
        players: [Player] = [],
        trackOverallScore: Bool = false,
        tipsCount: Int = 3,
        separateRanking: Bool = false
    ) {
        self.category = category
        self.selectedDifficulty = selectedDifficulty
        self.persistentMode = persistentMode
        self.totalRounds = totalRounds
        self.tipsCount = tipsCount
        self.separateRanking = separateRanking
        _vm = StateObject(wrappedValue: GameViewModel(
            category: category,
            difficulty: selectedDifficulty,
            persistentMode: persistentMode,
            totalRounds: totalRounds,
            players: players,
            trackOverallScore: trackOverallScore,
            tipsCount: tipsCount,
            separateRanking: separateRanking
        ))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: themeManager.palette.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if vm.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.palette.screenTextPrimary))
                        .scaleEffect(1.3)
                    Text("Fragen werden geladen…")
                        .font(.subheadline)
                        .foregroundColor(themeManager.palette.screenTextSecondary)
                }
            } else if vm.isOutOfQuestions {
                EndOfQuestionsView(
                    players: vm.players,
                    trackOverallScore: vm.trackOverallScore
                ) {
                    dismiss()
                }
            } else {
                VStack(spacing: 32) {
                    header
                        .padding(.top, 8)
                    
                    questionCard
                    
                    stepIndicator
                    
                    if vm.quizState == .guessing {
                        guessingCard
                    } else {
                        tipsCard
                    }
                    
                    Spacer()
                    actionButtons
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Spiel wirklich beenden?", isPresented: $showExitAlert) {
            Button("Ja", role: .destructive) { dismiss() }
            Button("Nein", role: .cancel) { }
        } message: {
            Text("Dein aktueller Fortschritt in dieser Runde geht verloren.")
        }
        .alert("Fehler", isPresented: $vm.showError) {
            Button("Erneut versuchen") {
                Task {
                    await vm.loadQuestions()
                    vm.loadFirstQuestion()
                }
            }
            Button("Abbrechen", role: .cancel) { dismiss() }
        } message: {
            Text(vm.errorMessage ?? "Ein unbekannter Fehler ist aufgetreten.")
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack(spacing: 8) {
            Button { showExitAlert = true } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(themeManager.palette.screenTextPrimary)
                    .padding(8)
                    .background(themeManager.palette.cardBackground.opacity(0.4))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Zurück")
            .accessibilityHint("Beendet das aktuelle Spiel und kehrt zum Menü zurück")
            
            Text(category)
                .font(.subheadline)
                .foregroundColor(themeManager.palette.cardTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(themeManager.palette.cardBackground))
                .shadow(radius: 5, y: 3)
            
            Text(selectedDifficulty.displayName)
                .font(.subheadline)
                .foregroundColor(themeManager.palette.cardTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(themeManager.palette.cardBackground))
                .shadow(radius: 5, y: 3)
            
            RoundIndicatorView(current: currentRound, total: totalRounds)
                .environmentObject(themeManager)
            
            Spacer()
            
            if totalRounds == nil && vm.trackOverallScore {
                Button {
                    vm.isOutOfQuestions = true
                } label: {
                    Text("Beenden")
                        .font(.subheadline.bold())
                        .foregroundColor(themeManager.palette.onPrimaryButton)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.palette.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Animierte Fragekarte
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frage")
                .font(.caption)
                .foregroundColor(themeManager.palette.cardTextSecondary)
            
            Text(vm.currentQuestion?.question ?? "")
                .font(.title3.weight(.semibold))
                .foregroundColor(themeManager.palette.cardTextPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(themeManager.palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        .padding(.horizontal)
        .opacity(animateQuestion ? 1 : 0)
        .offset(y: animateQuestion ? 0 : 16)
        .scaleEffect(animateQuestion ? 1 : 0.97)
        .id(questionID)
        .onAppear { runQuestionAnimation() }
    }

    private func runQuestionAnimation() {
        animateQuestion = false
        withAnimation(.easeOut(duration: 0.35)) {
            animateQuestion = true
        }
    }

    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack {
            Text(vm.stepTitle)
                .font(.subheadline)
                .foregroundColor(themeManager.palette.screenTextPrimary)
            
            Spacer()
            
            HStack(spacing: 6) {
                ForEach(0..<vm.totalSteps, id: \.self) { index in
                    let isActive = index == vm.currentStepIndex
                    Circle()
                        .frame(width: isActive ? 10 : 6,
                               height: isActive ? 10 : 6)
                        .foregroundColor(
                            index <= vm.currentStepIndex
                            ? themeManager.palette.screenTextPrimary
                            : themeManager.palette.screenTextPrimary.opacity(0.4)
                        )
                        .scaleEffect(isActive ? 1.25 : 1)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Guessing
    private var guessingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            let currentPlayer = vm.players[vm.currentPlayerGuessIndex]
            Text("Tipp von \(currentPlayer.name)")
                .font(.headline)
                .foregroundColor(themeManager.palette.cardTextPrimary)
            
            HStack(spacing: 12) {
                TextField("Deine Zahl...", text: Binding(
                    get: { vm.currentGuesses[currentPlayer.id, default: ""] },
                    set: { newValue in
                        let allowed = "0123456789.,"
                        let filtered = newValue.filter { allowed.contains($0) }
                        vm.currentGuesses[currentPlayer.id] = filtered
                    }
                ))
                .focused($isInputFocused)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .padding(12)
                .background(themeManager.palette.cardBackground.opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.palette.border, lineWidth: 1)
                )
                .font(.title2)
                .accessibilityLabel("Tipp eingeben für \(currentPlayer.name)")
                
                if let dimension = vm.currentQuestion?.dimension, dimension != .none {
                    Picker("Einheit", selection: Binding(
                        get: { vm.currentUnitSelections[currentPlayer.id] ?? dimension.defaultIndex },
                        set: { vm.currentUnitSelections[currentPlayer.id] = $0 }
                    )) {
                        ForEach(Array(dimension.options.enumerated()), id: \.offset) { index, option in
                            Text(option.label).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(themeManager.palette.accent)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 4)
                    .background(themeManager.palette.cardBackground.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.palette.border, lineWidth: 1)
                    )
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isInputFocused = true
                }
            }
            
            if vm.isPrimaryDisabled,
               let current = vm.currentGuesses[currentPlayer.id],
               !current.isEmpty,
               Double(current.replacingOccurrences(of: ",", with: ".")) == nil {
                Text("Bitte gib eine gültige Zahl ein")
                    .font(.caption)
                    .foregroundColor(Color.red)
                    .padding(.top, 4)
                    .accessibilityLabel("Ungültige Zahl")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        .padding(.horizontal)
    }

    // MARK: - Tipps
    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            if vm.quizState == .question {
                
                Text("Tipps werden hier eingeblendet.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.palette.cardTextSecondary)
                
            } else {
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.visibleTips(), id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundColor(themeManager.palette.bulletColor)
                                .padding(.top, 6)
                            
                            Text(tip)
                                .foregroundColor(themeManager.palette.cardTextPrimary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // MARK: - Antwort
            if vm.quizState == .answer || vm.quizState == .ranking {

                // Divider nur im Persistent Mode anzeigen
                if persistentMode && tipsCount > 0 {
                    Divider().padding(8)
                }

                Text("Antwort")
                    .font(.caption)
                    .foregroundColor(themeManager.palette.cardTextSecondary)

                if let legacy = vm.currentQuestion?.answer {
                    Text(legacy)
                        .font(.title3.bold())
                        .foregroundColor(themeManager.palette.cardTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let base = vm.currentQuestion?.answerBaseValue {
                    let formatted = vm.formatNumber(base)
                    let text = vm.currentQuestion?.defaultUnitText ?? ""
                    Text("\(formatted) \(text)")
                        .font(.title3.bold())
                        .foregroundColor(themeManager.palette.cardTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if !vm.players.isEmpty && !vm.currentRanking.isEmpty && (!separateRanking || vm.quizState == .ranking) {
                    Divider().padding(.vertical, 8)
                    Text("Rangliste")
                        .font(.headline)
                        .foregroundColor(themeManager.palette.cardTextPrimary)
                    
                    ForEach(Array(vm.currentRanking.enumerated()), id: \.element.player.id) { index, item in
                        HStack {
                            Text("\(index + 1).")
                                .font(.subheadline.bold())
                                .foregroundColor(themeManager.palette.cardTextSecondary)
                            Text(item.player.name)
                                .font(.subheadline)
                                .foregroundColor(themeManager.palette.cardTextPrimary)
                            Spacer()
                            
                            let unitText = vm.currentQuestion?.defaultUnitText ?? ""
                            let formattedGuess = item.guess == Double.greatestFiniteMagnitude || item.guess.isNaN ? "?" : vm.formatNumber(item.guess)
                            Text("Tipp: \(formattedGuess) \(unitText)")
                                .font(.caption)
                                .foregroundColor(themeManager.palette.cardTextSecondary)
                            
                            if item.points > 0 && vm.trackOverallScore {
                                Text("+\(item.points)")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(themeManager.palette.accent.opacity(0.2))
                                    .foregroundColor(themeManager.palette.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        .padding(.horizontal)
    }

    // MARK: - Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(vm.primaryButtonTitle) {
                let previous = vm.quizState
                vm.nextState()

                switch vm.quizState {
                case .tip1, .tip2, .tip3, .answer:
                    SoundManager.shared.play(.reveal)
                case .ranking:
                    SoundManager.shared.play(.success)
                default:
                    SoundManager.shared.play(.tap)
                }

                if previous == .answer {
                    questionID = UUID()
                    if let total = totalRounds, currentRound < total { currentRound += 1 }
                    else if totalRounds == nil { currentRound += 1 }
                }
            }
            .disabled(vm.isPrimaryDisabled)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(LinearGradient(
                colors: vm.isPrimaryDisabled ? [.gray, .gray.opacity(0.8)] : themeManager.palette.primaryButtonGradient,
                startPoint: .leading, endPoint: .trailing))
            .foregroundColor(themeManager.palette.onPrimaryButton)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: themeManager.palette.primaryButtonGradient.first?.opacity(0.7) ?? .black,
                    radius: 12, y: 6)
            
            if vm.canStepBack {
                Button("Einen Schritt zurück") {
                    haptics.light()
                    SoundManager.shared.play(.tap)
                    vm.stepBack()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundColor(themeManager.palette.screenTextPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(themeManager.palette.screenTextPrimary.opacity(0.5), lineWidth: 1)
                )
            }
            
            if vm.canSkip {
                Button("Frage überspringen") {
                    haptics.light()
                    SoundManager.shared.play(.tap)
                    vm.skip()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundColor(themeManager.palette.screenTextPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(themeManager.palette.screenTextPrimary.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}
