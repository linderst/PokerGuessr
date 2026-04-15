//
//  RoundIndicatorView.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 04.12.2025.
//

import SwiftUI

struct RoundIndicatorView: View {
    let current: Int
    let total: Int?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Text(labelText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(themeManager.palette.screenTextPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(themeManager.palette.cardBackground.opacity(0.4))
            )
    }
    
    private var labelText: String {
        if let total = total {
            return "\(current) / \(total) Runden"
        } else {
            return "Unbegrenzte Runden"
        }
    }
}
