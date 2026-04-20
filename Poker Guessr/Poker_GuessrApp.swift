//
//  Poker_GuessrApp.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 02.12.2025.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct PokerGuessrApp: App {

    @StateObject var themeManager = ThemeManager()
    @StateObject var hapticsManager = HapticsManager.shared

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

    init() {
        FirebaseApp.configure()

        // Firestore Offline-Cache aktivieren (100 MB)
        // Fragen bleiben nach erstem Laden offline verfügbar.
        let settings = Firestore.firestore().settings
        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: NSNumber(value: 100 * 1024 * 1024)
        )
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            MenuView()
                .environmentObject(themeManager)
                .environmentObject(hapticsManager)
                .onAppear {
                    if !hasSeenOnboarding {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
                    hasSeenOnboarding = true
                }) {
                    OnboardingView(isPresented: $showOnboarding)
                        .environmentObject(themeManager)
                        .environmentObject(hapticsManager)
                }
        }
    }
}

#Preview {
    MenuView()
        .environmentObject(ThemeManager())
        .environmentObject(HapticsManager())
}
