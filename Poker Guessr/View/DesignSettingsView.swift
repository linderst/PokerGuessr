import SwiftUI

struct DesignSettingsView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            RootBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Design")
                        .font(.largeTitle.bold())
                        .foregroundColor(themeManager.palette.screenTextPrimary)
                        .padding(.top, 8)
                    
                    Text("Wähle einen Look für deine Runden.")
                        .font(.subheadline)
                        .foregroundColor(themeManager.palette.screenTextSecondary)
                    
                    ForEach(AppTheme.allCases) { theme in
                        themeCard(for: theme)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Design")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.palette.bulletColor)
    }
    
    private func themeCard(for theme: AppTheme) -> some View {
        let selected = themeManager.currentTheme == theme
        
        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                themeManager.currentTheme = theme
            }
        } label: {
            HStack(spacing: 16) {
                Text(theme.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(previewText(for: theme))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: previewGradient(for: theme),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selected ? Color.white : Color.white.opacity(0.3),
                            lineWidth: selected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: selected ? 10 : 4, y: 4)
        }
    }
    
    private func previewGradient(for theme: AppTheme) -> [Color] {
        switch theme {
        case .oceanBlue:      return [Color.blue.opacity(0.9), Color.teal.opacity(0.9)]
        case .sunsetBurst:    return [Color.orange.opacity(0.9), Color.pink.opacity(0.9)]
        case .midnightPurple: return [Color.purple.opacity(0.9), Color.black.opacity(0.9)]
        case .forestGreen:    return [Color.green.opacity(0.9), Color.teal.opacity(0.9)]
        }
    }
    
    private func previewText(for theme: AppTheme) -> String {
        switch theme {
        case .oceanBlue:      return "Klar, frisch, fokussiert."
        case .sunsetBurst:    return "Warm, energiegeladen."
        case .midnightPurple: return "Dunkel, ruhig, konzentriert."
        case .forestGreen:    return "Natürlich, entspannt."
        }
    }
}
