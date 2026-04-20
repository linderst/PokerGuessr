//
//  EndOfQuestionsView.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 04.12.2025.
//

import SwiftUI
import StoreKit

struct EndOfQuestionsView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var haptics: HapticsManager
    @Environment(\.requestReview) private var requestReview

    @AppStorage("completedGamesCount") private var completedGamesCount: Int = 0
    @AppStorage("lastReviewPromptVersion") private var lastReviewPromptVersion: String = ""

    var players: [Player] = []
    var trackOverallScore: Bool = false
    let onBackToMenu: () -> Void

    @State private var showShareSheet = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var shareText: String {
        var text = "🎲 Ich habe gerade Poker Guessr gespielt!"
        if trackOverallScore && !players.isEmpty {
            let sorted = players.sorted { $0.score > $1.score }
            if let winner = sorted.first {
                text += "\n🏆 Sieger: \(winner.name) mit \(winner.score) Punkten"
            }
        }
        text += "\n\nLade die App und rate mit: https://pokerguessr.com"
        return text
    }

    var body: some View {
        VStack(spacing: 32) {

            Spacer()

            // MARK: - Hauptkarte
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundColor(themeManager.palette.accent)
                    .shadow(color: themeManager.palette.accent.opacity(0.4), radius: 12, y: 4)
                    .padding(.bottom, 4)

                Text("Alle Fragen gespielt!")
                    .font(.title.bold())
                    .foregroundColor(themeManager.palette.cardTextPrimary)

                Text("Es sind aktuell keine weiteren Fragen in dieser Kategorie verfügbar.\nNeue Inhalte folgen bald!")
                    .font(.body)
                    .foregroundColor(themeManager.palette.cardTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if trackOverallScore && !players.isEmpty {
                    Divider().padding(.vertical, 8)
                    Text("Endstand")
                        .font(.headline)
                        .foregroundColor(themeManager.palette.cardTextPrimary)

                    let sorted = players.sorted { $0.score > $1.score }
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, player in
                        HStack {
                            Text("\(index + 1).")
                                .font(.subheadline.bold())
                                .foregroundColor(themeManager.palette.cardTextSecondary)
                            Text(player.name)
                                .font(.subheadline)
                                .foregroundColor(themeManager.palette.cardTextPrimary)
                            Spacer()
                            Text("\(player.score) Pkt")
                                .font(.subheadline.bold())
                                .foregroundColor(themeManager.palette.accent)
                        }
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.palette.cardBackground)
                    .shadow(color: themeManager.palette.border.opacity(0.25), radius: 12, y: 6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            Spacer()

            // MARK: - Buttons
            VStack(spacing: 12) {
                Button(action: {
                    haptics.light()
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Ergebnis teilen")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(themeManager.palette.cardTextPrimary)
                    .background(themeManager.palette.cardBackground.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(themeManager.palette.accent, lineWidth: 1.2)
                    )
                }
                .accessibilityLabel("Ergebnis teilen")

                Button(action: {
                    haptics.light()
                    onBackToMenu()
                }) {
                    Text("Zurück zum Menü")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(themeManager.palette.onPrimaryButton)
                        .background(
                            LinearGradient(
                                colors: themeManager.palette.primaryButtonGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(themeManager.palette.screenTextPrimary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 24)
        }
        .background(
            LinearGradient(
                colors: themeManager.palette.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .onAppear {
            completedGamesCount += 1
            SoundManager.shared.play(.complete)
            maybeRequestReview()
        }
    }

    private func maybeRequestReview() {
        guard completedGamesCount >= 2 else { return }
        guard lastReviewPromptVersion != appVersion else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            requestReview()
            lastReviewPromptVersion = appVersion
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
