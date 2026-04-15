import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager   // ← GLOBALER HAPTIK-MANAGER
    
    @Binding var selectedModePersistent: Bool
    @Binding var volume: Double
    @Binding var unlimitedRounds: Bool
    @Binding var roundCount: Int
    @Binding var hapticsEnabled: Bool
    @Binding var trackOverallScore: Bool
    @Binding var tipsCount: Int
    @Binding var separateRanking: Bool
    
    @State private var lastVolume: Double = 0.8
    
    var body: some View {
        NavigationStack {
            ZStack {
                RootBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // MARK: - Lautstärke
                        settingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Lautstärke")
                                    .font(.headline)
                                    .foregroundColor(themeManager.palette.cardTextPrimary)

                                HStack {
                                    Slider(value: $volume, in: 0...1)
                                        .tint(themeManager.palette.accent)

                                    Button {
                                        if volume == 0 {
                                            // Restore previous volume
                                            volume = lastVolume
                                            hapticsManager.light()
                                        } else {
                                            lastVolume = volume
                                            volume = 0
                                            hapticsManager.light()
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                                .font(.system(size: 16, weight: .bold))
                                                .frame(width: 20, height: 20)
                                        }
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(themeManager.palette.cardBackground.opacity(0.9))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(themeManager.palette.accent, lineWidth: 1.2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(volume == 0 ? "Stumm aus" : "Stummschalten")
                                    .accessibilityHint("Tippe, um die Lautstärke zu stummschalten oder wiederherzustellen")
                                    .shadow(color: themeManager.palette.border.opacity(0.4), radius: 4, y: 2)
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
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Punkte")
                                    .font(.headline)
                                    .foregroundColor(themeManager.palette.cardTextPrimary)

                                Toggle(isOn: $trackOverallScore) {
                                    Text("Gesamtsieger ermitteln")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                                .accessibilityLabel("Gesamtsieger ermitteln")
                                .accessibilityHint("Sammelt die Punkte über alle gespielten Runden")
                            }
                        }
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

