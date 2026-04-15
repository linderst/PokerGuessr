//
//  PokerChipView.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 04.12.2025.
//


import SwiftUI

struct PokerChipView: View {
    
    @State private var rotate: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Image("pokerchip_neutral")
            .resizable()
            .scaledToFit()
            .frame(width: 140, height: 140)
            .rotationEffect(.degrees(rotate))
            .scaleEffect(scale)
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    scale = 0.85
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1)) {
                    scale = 1.0
                    rotate += 360
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    scale = 1.05
                }
            }
    }
}