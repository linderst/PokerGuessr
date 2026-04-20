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
                    VStack(alignment: .leading, spacing: 4) {

                        // MARK: - Sound
                        sectionHeader("Sound")
                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
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
                        sectionHeader("Haptik")
                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
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
                        sectionHeader("Runden")
                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Toggle(isOn: $unlimitedRounds) {
                                    Text("Unbegrenzt")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                                .accessibilityLabel("Unbegrenzte Runden")
                                .accessibilityHint("Wenn aktiviert, wird ohne Rundenlimit gespielt")

                                if !unlimitedRounds {
                                    counterRow(
                                        label: "Runden: \(roundCount)",
                                        value: $roundCount,
                                        range: 1...20,
                                        accessibilityLabel: "Rundenanzahl"
                                    )
                                }
                            }
                        }
                        
                        // MARK: - Spiellogik
                        sectionHeader("Spiellogik")
                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Toggle(isOn: $selectedModePersistent) {
                                    Text("Tipps merken")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                                .accessibilityLabel("Tipps merken")
                                .accessibilityHint("Merkt sich deine Tipp-Einstellungen für kommende Spiele")

                                Divider().background(themeManager.palette.cardTextSecondary.opacity(0.3))

                                HStack {
                                    Text("Tipps pro Frage")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                    Spacer()
                                    themedSegments(values: [1, 2, 3], selection: $tipsCount)
                                        .accessibilityLabel("Tipps pro Frage")
                                        .accessibilityValue("\(tipsCount)")
                                }
                                
                                Divider().background(themeManager.palette.cardTextSecondary.opacity(0.3))
                                
                                // Getrennte Rangliste
                                Toggle(isOn: $separateRanking) {
                                    Text("Lösung als Tipp verwenden")
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                }
                                .tint(themeManager.palette.accent)
                            }
                        }
                        
                        // MARK: - Punkte
                        sectionHeader("Punkte")
                        settingsCard {
                            VStack(alignment: .leading, spacing: 6) {
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

    // MARK: - Section Header (iOS-Style minimal)
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption)
            .tracking(1.2)
            .foregroundColor(themeManager.palette.screenTextSecondary)
            .padding(.horizontal, 4)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    // MARK: - Themed Segments (Ersatz für SegmentedPicker)
    @ViewBuilder
    private func themedSegments(values: [Int], selection: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            ForEach(values, id: \.self) { value in
                let isSelected = selection.wrappedValue == value
                Button {
                    if !isSelected {
                        selection.wrappedValue = value
                        hapticsManager.light()
                    }
                } label: {
                    Text("\(value)")
                        .font(.subheadline.bold())
                        .frame(width: 36, height: 32)
                        .foregroundColor(isSelected
                                         ? themeManager.palette.onPrimaryButton
                                         : themeManager.palette.cardTextPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected
                                      ? themeManager.palette.accent
                                      : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeManager.palette.accent.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(themeManager.palette.accent.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Counter Row (sichtbarer Ersatz für Stepper)
    @ViewBuilder
    private func counterRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        accessibilityLabel: String
    ) -> some View {
        HStack {
            Text(label)
                .foregroundColor(themeManager.palette.accent)

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= 1
                        hapticsManager.light()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.body.bold())
                        .frame(width: 44, height: 32)
                        .foregroundColor(value.wrappedValue > range.lowerBound
                                         ? themeManager.palette.accent
                                         : themeManager.palette.cardTextSecondary.opacity(0.4))
                }
                .disabled(value.wrappedValue <= range.lowerBound)
                .accessibilityLabel("\(accessibilityLabel) verringern")

                Divider()
                    .frame(height: 20)
                    .background(themeManager.palette.accent.opacity(0.4))

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += 1
                        hapticsManager.light()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.body.bold())
                        .frame(width: 44, height: 32)
                        .foregroundColor(value.wrappedValue < range.upperBound
                                         ? themeManager.palette.accent
                                         : themeManager.palette.cardTextSecondary.opacity(0.4))
                }
                .disabled(value.wrappedValue >= range.upperBound)
                .accessibilityLabel("\(accessibilityLabel) erhöhen")
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.palette.accent.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(themeManager.palette.accent.opacity(0.5), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(value.wrappedValue)")
    }

    // MARK: - Card Wrapper
    @ViewBuilder
    private func settingsCard<Content: View>(_ content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: themeManager.palette.border.opacity(0.35), radius: 6, y: 3)
    }
}

