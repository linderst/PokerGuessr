//
//  RootBackground.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 04.12.2025.
//


import SwiftUI

struct RootBackground: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        LinearGradient(
            colors: themeManager.palette.backgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
