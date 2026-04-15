//
//  HapticsManager.swift
//  Poker Guessr
//
//  Created by Stefan Linder on 04.12.2025.
//


import Foundation
import UIKit
import Combine

@MainActor
class HapticsManager: ObservableObject {
    
    @Published var hapticsEnabled: Bool = true
    
    static let shared = HapticsManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    
    init() {}
    
    func light() {
        guard hapticsEnabled else { return }
        impactLight.impactOccurred()
    }
    
    func medium() {
        guard hapticsEnabled else { return }
        impactMedium.impactOccurred()
    }
    
    func heavy() {
        guard hapticsEnabled else { return }
        impactHeavy.impactOccurred()
    }
    
    func success() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }
    
    func error() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.error)
    }
}
