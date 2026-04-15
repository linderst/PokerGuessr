//
//  ThemePalette.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 04.12.2025.
//


import SwiftUI

extension Color {
    /// Vereinfachte Kontrastprüfung
    var isDark: Bool {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: nil)
        return (0.299*r + 0.587*g + 0.114*b) < 0.5
    }
}

struct ThemePalette {
    let backgroundGradient: [Color]
    let primaryButtonGradient: [Color]

    // Textfarben
    let screenTextPrimary: Color
    let screenTextSecondary: Color
    
    // Kartenfarben
    let cardBackground: Color
    let cardTextPrimary: Color
    let cardTextSecondary: Color
    let bulletColor: Color
    
    // Zusätzliche Theme-Farben
    let accent: Color           // z. B. Toggle, Switch, Slider
    let border: Color
    let materialStyle: Material // Light/Dark abhängig
    let onPrimaryButton: Color  // Textfarbe auf Buttons
}
