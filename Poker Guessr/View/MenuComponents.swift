import SwiftUI

// MARK: - Animierter Poker-Titel
struct AnimatedPokerTitle: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        let accent = themeManager.palette.accent
        
        Text("Poker Guessr")
            .font(.system(size: 44, weight: .heavy, design: .rounded))
            .foregroundColor(themeManager.palette.screenTextPrimary)
            .neonGlow(color: accent)
            .scaleEffect(pulse)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                ) { pulse = 1.07 }
            }
    }
}

// MARK: - Untertitel-Info
struct SublineInfo: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 6) {
            Divider()
                .background(themeManager.palette.accent.opacity(0.6))
                .shadow(color: themeManager.palette.accent.opacity(0.5), radius: 8)
            
            Text("Teste dein Wissen mit Tipps & Poker-Mindgames")
                .font(.subheadline)
                .foregroundColor(themeManager.palette.screenTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Divider()
                .background(themeManager.palette.accent.opacity(0.6))
                .shadow(color: themeManager.palette.accent.opacity(0.5), radius: 8)
        }
    }
}

// MARK: - Rotierender Pokerchip-Icon
struct AnimatedPokerChipIcon: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var rotation: Double = 0
    
    var body: some View {
        let accent = themeManager.palette.accent
        let primary = themeManager.palette.screenTextPrimary
        
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 10
                )
                .frame(width: 90, height: 90)
                .shadow(color: accent.opacity(0.5), radius: 12)
                .shadow(color: accent.opacity(0.2), radius: 20)
            
            Circle()
                .fill(themeManager.palette.cardBackground)
                .frame(width: 65, height: 65)
                .shadow(color: .black.opacity(0.25), radius: 6)
            
            Text("?")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(primary)
                .shadow(color: accent.opacity(0.8), radius: 10)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(
                .linear(duration: 4.0).repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

// MARK: - Schwierigkeitsgrad-Auswahl
struct DifficultySelector: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager
    @Binding var selectedDifficulty: Difficulty
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Difficulty.allCases, id: \.self) { option in
                let isSelected = selectedDifficulty == option
                
                Button {
                    selectedDifficulty = option
                    hapticsManager.light()
                } label: {
                    Text(option.displayName)
                        .font(.subheadline.bold())
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSelected
                                      ? themeManager.palette.accent.opacity(0.9)
                                      : themeManager.palette.cardBackground.opacity(0.4))
                                .shadow(color: isSelected ? themeManager.palette.accent.opacity(0.6) : .clear,
                                        radius: 8, y: 3)
                        )
                        .foregroundColor(
                            isSelected
                            ? themeManager.palette.onPrimaryButton
                            : themeManager.palette.screenTextPrimary
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}
