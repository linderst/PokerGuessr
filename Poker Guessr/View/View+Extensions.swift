import SwiftUI

extension View {
    /// Neon-Glow-Effekt mit doppeltem Schatten für leuchtende UI-Elemente.
    func neonGlow(color: Color) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: 12)
            .shadow(color: color.opacity(0.4), radius: 24)
    }
    
    /// Wendet einen Modifier nur an, wenn die Bedingung `true` ist.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
