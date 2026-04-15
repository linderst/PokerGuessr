//
//  ThemedCard.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 04.12.2025.
//


import SwiftUI

struct ThemedCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.palette.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeManager.palette.border, lineWidth: 1)
            )
            .shadow(
                color: themeManager.palette.cardBackground.isDark
                    ? .black.opacity(0.5)
                    : .black.opacity(0.12),
                radius: themeManager.palette.cardBackground.isDark ? 8 : 5,
                y: themeManager.palette.cardBackground.isDark ? 6 : 4
            )
    }
}