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

    var body: some View {
        NavigationStack {
            ZStack {
                RootBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

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

