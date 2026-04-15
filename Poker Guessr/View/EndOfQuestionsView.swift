//
//  EndOfQuestionsView.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 04.12.2025.
//

import SwiftUI

struct EndOfQuestionsView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var haptics: HapticsManager

    var players: [Player] = []
    var trackOverallScore: Bool = false
    let onBackToMenu: () -> Void
    
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
            
            // MARK: - Button
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
                    .padding(.horizontal)
            }
            
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
    }
}
