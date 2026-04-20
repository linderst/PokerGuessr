import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager   // ← GLOBALER HAPTIK-MANAGER
    
    @Binding var selectedModePersistent: Bool
    @Binding var unlimitedRounds: Bool
    @Binding var roundCount: Int
    @Binding var hapticsEnabled: Bool
    @Binding var trackOverallScore: Bool
    @Binding var tipsCount: Int
    @Binding var separateRanking: Bool

    @AppStorage("isMultiplayerMode") private var isMultiplayerMode: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("soundVolume") private var soundVolume: Double = 0.7

    var body: some View {
        NavigationStack {
            ZStack {
                RootBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

                        // MARK: - Sound
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sound")
                                    .font(.headline)
                                    .foregroundColor(themeManager.palette.cardTextPrimary)

                                Toggle(isOn: $soundEnabled) {
                                    Text("Sound einschalten")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                                .accessibilityLabel("Sound")
                                .accessibilityHint("Schalte Soundeffekte ein oder aus")
                                .onChange(of: soundEnabled) { _, newValue in
                                    if newValue { SoundManager.shared.play(.tap) }
                                }

                                if soundEnabled {
                                    HStack(spacing: 12) {
                                        Image(systemName: "speaker.fill")
                                            .foregroundColor(themeManager.palette.cardTextSecondary)
                                        Slider(value: $soundVolume, in: 0...1) { editing in
                                            if !editing { SoundManager.shared.play(.tap) }
                                        }
                                        .tint(themeManager.palette.accent)
                                        .accessibilityLabel("Lautstärke")
                                        .accessibilityValue("\(Int(soundVolume * 100)) Prozent")
                                        Image(systemName: "speaker.wave.3.fill")
                                            .foregroundColor(themeManager.palette.cardTextSecondary)
                                    }
                                }
                            }
                        }

                        // MARK: - Haptik
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Haptik")
                                    .font(.headline)
                                    .foregroundColor(themeManager.palette.cardTextPrimary)

                                Toggle(isOn: $hapticsEnabled) {
                                    Text("Haptik einschalten")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                                .accessibilityLabel("Haptik")
                                .accessibilityHint("Schalte haptisches Feedback ein oder aus")
                                .onChange(of: hapticsEnabled) { oldValue, newValue in
                                    hapticsManager.hapticsEnabled = newValue
                                    
                                    if newValue {
                                        hapticsManager.light()   // Mini-Feedback beim Aktivieren
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Runden
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Runden")
                                    .font(.headline)
                                    .foregroundColor(themeManager.palette.cardTextPrimary)

                                Toggle(isOn: $unlimitedRounds) {
                                    Text("Unbegrenzt")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                                .accessibilityLabel("Unbegrenzte Runden")
                                .accessibilityHint("Wenn aktiviert, wird ohne Rundenlimit gespielt")

                                if !unlimitedRounds {
                                    Stepper(value: $roundCount, in: 1...20) {
                                        Text("Runden: \(roundCount)")
                                            .foregroundColor(themeManager.palette.accent)
                                    }
                                    .colorScheme(themeManager.palette.cardBackground.isDark ? .dark : .light)
                                    .accessibilityLabel("Rundenanzahl")
                                    .accessibilityValue("\(roundCount)")
                                    .accessibilityHint("Erhöhe oder verringere die Anzahl der Runden")
                                }
                            }
                        }
                        
                        // MARK: - Tipps
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tipps")
                                    .font(.headline)
                                    .foregroundColor(themeManager.palette.cardTextPrimary)

                                Toggle(isOn: $selectedModePersistent) {
                                    Text("Tipps merken")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                                .accessibilityLabel("Tipps merken")
                                .accessibilityHint("Merkt sich deine Tipp-Einstellungen für kommende Spiele")
                            }
                        }
                        // MARK: - Spiellogik
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Spiellogik")
                                    .font(.headline)
                                    .foregroundColor(themeManager.palette.cardTextPrimary)

                                // Tipps pro Frage Stepper
                                Stepper(value: $tipsCount, in: 0...3) {
                                    Text("Tipps pro Frage: \(tipsCount)")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .colorScheme(themeManager.palette.cardBackground.isDark ? .dark : .light)
                                
                                Divider().background(themeManager.palette.cardTextSecondary.opacity(0.3))
                                
                                // Getrennte Rangliste
                                Toggle(isOn: $separateRanking) {
                                    Text("Lösung und Rangliste trennen")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                            }
                        }
                        
                        // MARK: - Punkte
                        settingsCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Punkte")
                                    .font(.headline)
                                    .foregroundColor(themeManager.palette.cardTextPrimary)

                                Toggle(isOn: $trackOverallScore) {
                                    Text("Gesamtsieger ermitteln")
                                        .foregroundColor(isMultiplayerMode
                                                         ? themeManager.palette.cardTextPrimary
                                                         : themeManager.palette.cardTextSecondary)
                                }
                                .tint(themeManager.palette.accent)
                                .disabled(!isMultiplayerMode)
                                .accessibilityLabel("Gesamtsieger ermitteln")
                                .accessibilityHint(isMultiplayerMode
                                                   ? "Sammelt die Punkte über alle gespielten Runden"
                                                   : "Nur im Multiplayer-Modus verfügbar")

                                if !isMultiplayerMode {
                                    Text("Nur im Multiplayer-Modus verfügbar")
                                        .font(.caption)
                                        .foregroundColor(themeManager.palette.cardTextSecondary)
                                        .padding(.top, 2)
                                }
                            }
                        }

                        // MARK: - Info
                        NavigationLink {
                            AboutView()
                                .environmentObject(themeManager)
                                .environmentObject(hapticsManager)
                        } label: {
                            settingsCard {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(themeManager.palette.accent)
                                    Text("Info & Rechtliches")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(themeManager.palette.cardTextSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
            .navigationTitle("Einstellungen")
            .foregroundColor(themeManager.palette.screenTextPrimary)
        }
    }

    // MARK: - Card Wrapper
    @ViewBuilder
    private func settingsCard<Content: View>(_ content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: themeManager.palette.border.opacity(0.6), radius: 10, y: 5)
    }
}

