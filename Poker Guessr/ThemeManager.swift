import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case oceanBlue
    case sunsetBurst
    case midnightPurple
    case forestGreen
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .oceanBlue:      return "Ocean Blue"
        case .sunsetBurst:    return "Sunset"
        case .midnightPurple: return "Midnight"
        case .forestGreen:    return "Forest"
        }
    }
    
    var emoji: String {
        switch self {
        case .oceanBlue:      return "🌊"
        case .sunsetBurst:    return "🌅"
        case .midnightPurple: return "🌌"
        case .forestGreen:    return "🌲"
        }
    }
}


@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .oceanBlue
    
    var palette: ThemePalette {
        switch currentTheme {
        case .oceanBlue:
            return ThemePalette(
                backgroundGradient: [Color.blue.opacity(0.7), Color.teal.opacity(0.7)],
                primaryButtonGradient: [Color.blue, Color.teal],
                
                screenTextPrimary: .white,
                screenTextSecondary: .white.opacity(0.8),
                
                cardBackground: Color.white.opacity(0.96),
                cardTextPrimary: .black,
                cardTextSecondary: .gray,
                bulletColor: .teal,
                
                accent: .teal,
                border: .white.opacity(0.3),
                materialStyle: .thinMaterial,
                onPrimaryButton: .white
            )
        case .sunsetBurst:
            return ThemePalette(
                backgroundGradient: [Color.orange.opacity(0.85), Color.pink.opacity(0.85)],
                primaryButtonGradient: [Color.orange, Color.pink],
                
                screenTextPrimary: .white,
                screenTextSecondary: .white.opacity(0.85),
                
                cardBackground: Color.white.opacity(0.96),
                cardTextPrimary: .black,
                cardTextSecondary: .gray,
                bulletColor: Color.orange,
                
                accent: .orange,
                border: .black.opacity(0.18),
                materialStyle: .thinMaterial,
                onPrimaryButton: .white
            )
        case .midnightPurple:
            return ThemePalette(
                backgroundGradient: [Color.purple.opacity(0.9), Color.black],
                primaryButtonGradient: [Color.purple, Color.indigo],
                
                screenTextPrimary: .white,
                screenTextSecondary: .white.opacity(0.7),
                
                cardBackground: Color.black.opacity(0.65),
                cardTextPrimary: .white,
                cardTextSecondary: .white.opacity(0.5),
                bulletColor: Color.purple.opacity(0.9),
                
                accent: .purple,
                border: .white.opacity(0.3),
                materialStyle: .ultraThinMaterial,
                onPrimaryButton: .white
            )
        case .forestGreen:
            return ThemePalette(
                backgroundGradient: [Color.green.opacity(0.8), Color.teal.opacity(0.8)],
                primaryButtonGradient: [Color.green, Color.teal],
                
                screenTextPrimary: .white,
                screenTextSecondary: .white.opacity(0.85),
                
                cardBackground: Color.white.opacity(0.97),
                cardTextPrimary: .black,
                cardTextSecondary: .gray,
                bulletColor: .green,
                
                accent: .green,
                border: .black.opacity(0.15),
                materialStyle: .thinMaterial,
                onPrimaryButton: .white
            )
        }
    }
}
