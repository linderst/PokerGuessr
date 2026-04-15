//
//  Poker_GuessrApp.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 02.12.2025.
//

import SwiftUI
import FirebaseCore

@main
struct PokerGuessrApp: App {
    
    @StateObject var themeManager = ThemeManager()
    @StateObject var hapticsManager = HapticsManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MenuView()
                .environmentObject(themeManager)
                .environmentObject(hapticsManager)
        }
    }
}

#Preview {
    MenuView()
        .environmentObject(ThemeManager())
        .environmentObject(HapticsManager())
}

