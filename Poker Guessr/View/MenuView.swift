import SwiftUI
import Foundation

struct MenuView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager
    
    @State private var selectedCategory: String = QuestionCategory.alle.rawValue
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var showCategorySheet = false
    @State private var showSettings = false
    @State private var showThemeSettings = false
    @State private var startGame = false
    @State private var players: [Player] = []
    @State private var newPlayerName: String = ""
    
    @AppStorage("selectedModePersistent") private var selectedModePersistent: Bool = true
    
    // Settings
    @AppStorage("unlimitedRounds") private var unlimitedRounds: Bool = false
    @AppStorage("roundCount") private var roundCount: Int = 8
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("trackOverallScore") private var trackOverallScore: Bool = false
    @AppStorage("isMultiplayerMode") private var isMultiplayerMode: Bool = true
    @AppStorage("tipsCount") private var tipsCount: Int = 2
    @AppStorage("useSolutionAsTip") private var separateRanking: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                RootBackground()
                
                VStack(spacing: 16) {
                    // MARK: - Titel
                    AnimatedPokerTitle()
                        .padding(.top, 20)

                    // MARK: - Pokerchip Icon
                    PokerChipView()

                    // MARK: - Spieler (oberhalb der fixen Controls)
                    if isMultiplayerMode {
                        PlayersSection(
                            players: $players,
                            newPlayerName: $newPlayerName
                        )
                        .padding(.bottom, 20)
                    } else {
                        Spacer(minLength: 0)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 20) {
                        // MARK: - Spielmodus (Single / Multi)
                        Picker("Spielmodus", selection: $isMultiplayerMode) {
                            Text("Nur Fragen").tag(false)
                            Text("Multiplayer").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                        // MARK: - Kategorie-Auswahl
                        Button {
                            hapticsManager.light()
                            showCategorySheet = true
                        } label: {
                            ThemedCard {
                                HStack {
                                    Text("Kategorie")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)

                                    Spacer()

                                    Text(selectedCategory)
                                        .foregroundColor(themeManager.palette.cardTextSecondary)

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(themeManager.palette.cardTextSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Kategorie: \(selectedCategory)")
                        .accessibilityHint("Tippe, um die Kategorie zu ändern")
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                        // MARK: - Schwierigkeitsgrad
                        DifficultySelector(selectedDifficulty: $selectedDifficulty)
                            .padding(.horizontal)

                        // MARK: - Start-Button
                        startButton
                    }
                }
            }
            .onAppear {
                hapticsManager.hapticsEnabled = hapticsEnabled
            }
            .onChange(of: hapticsEnabled) { _, newValue in
                hapticsManager.hapticsEnabled = newValue
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        hapticsManager.light()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.palette.screenTextPrimary)
                    }
                    .accessibilityLabel("Einstellungen")
                    .accessibilityHint("Öffnet die Einstellungen")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        hapticsManager.light()
                        showThemeSettings = true
                    } label: {
                        Image(systemName: "paintbrush.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.palette.screenTextPrimary)
                    }
                    .accessibilityLabel("Design")
                    .accessibilityHint("Öffnet die Designauswahl")
                }
            }
            .navigationDestination(isPresented: $startGame) {
                GameView(
                    category: selectedCategory,
                    selectedDifficulty: selectedDifficulty,
                    persistentMode: selectedModePersistent,
                    totalRounds: unlimitedRounds ? nil : roundCount,
                    players: isMultiplayerMode ? players : [],
                    trackOverallScore: trackOverallScore,
                    tipsCount: tipsCount,
                    separateRanking: separateRanking
                )
                .environmentObject(hapticsManager)
            }
            .sheet(isPresented: $showCategorySheet) {
                CategorySheet(selectedCategory: $selectedCategory)
                    .environmentObject(themeManager)
                    .presentationDetents([.height(500)])
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(
                    selectedModePersistent: $selectedModePersistent,
                    unlimitedRounds: $unlimitedRounds,
                    roundCount: $roundCount,
                    hapticsEnabled: $hapticsEnabled,
                    trackOverallScore: $trackOverallScore,
                    tipsCount: $tipsCount,
                    separateRanking: $separateRanking
                )
                .environmentObject(themeManager)
                .environmentObject(hapticsManager)
            }
            .sheet(isPresented: $showThemeSettings) {
                DesignSettingsView()
                    .environmentObject(themeManager)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        VStack(spacing: 8) {
            Button {
                hapticsManager.medium()
                SoundManager.shared.play(.tap)
                startGame = true
            } label: {
                Text("Spiel starten")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: (isMultiplayerMode && players.count < 2) ? [.gray, .gray.opacity(0.8)] : themeManager.palette.primaryButtonGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(themeManager.palette.onPrimaryButton)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: themeManager.palette.primaryButtonGradient.first?.opacity(0.9) ?? .black,
                            radius: 14, y: 7)
            }
            .disabled(isMultiplayerMode && players.count < 2)
            .accessibilityLabel("Spiel starten")
            .accessibilityHint(isMultiplayerMode && players.count < 2
                               ? "Füge mindestens zwei Spieler hinzu, um zu starten"
                               : "Startet eine neue Runde")
            .overlay(alignment: .bottom) {
                Text("Bitte füge mindestens 2 Spieler hinzu")
                    .font(.caption)
                    .foregroundColor(themeManager.palette.cardTextSecondary)
                    .opacity(isMultiplayerMode && players.count < 2 ? 1 : 0)
                    .offset(y: 24)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 50)
    }
}

#Preview {
    MenuView()
        .environmentObject(ThemeManager())
        .environmentObject(HapticsManager())
}
