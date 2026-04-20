import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let isAssetImage: Bool
    let title: String
    let description: String
}

struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager
    @Binding var isPresented: Bool

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "pokerchip_neutral",
            isAssetImage: true,
            title: "Willkommen bei Poker Guessr",
            description: "Das Schätzspiel mit Pokerchip-Charme. Allein oder mit Freunden – tippe Zahlen, gewinne Punkte."
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            isAssetImage: false,
            title: "Schätzen & Hinweise nutzen",
            description: "Du bekommst eine Frage mit einer Zahl als Antwort. Gib deinen Tipp ab und nutze bis zu drei Hinweise, um der Lösung näherzukommen."
        ),
        OnboardingPage(
            icon: "trophy.fill",
            isAssetImage: false,
            title: "Punkte sammeln",
            description: "Im Multiplayer-Modus gibt es für die besten Schätzungen 3, 2 und 1 Punkt. Wer am Ende die meisten Punkte hat, gewinnt."
        ),
        OnboardingPage(
            icon: "gearshape.2.fill",
            isAssetImage: false,
            title: "Alles anpassbar",
            description: "Wähle Kategorie, Schwierigkeitsgrad, Rundenzahl und Design ganz nach deinem Geschmack. Jetzt geht's los!"
        )
    ]

    var body: some View {
        ZStack {
            RootBackground()

            VStack(spacing: 24) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageView(page)
                            .tag(index)
                            .padding(.horizontal, 32)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage
                                  ? themeManager.palette.accent
                                  : themeManager.palette.screenTextSecondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        hapticsManager.medium()
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            finish()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Weiter" : "Los geht's")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: themeManager.palette.primaryButtonGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(themeManager.palette.onPrimaryButton)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }

                    if currentPage < pages.count - 1 {
                        Button {
                            hapticsManager.light()
                            finish()
                        } label: {
                            Text("Überspringen")
                                .font(.subheadline)
                                .foregroundColor(themeManager.palette.screenTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            iconBadge(for: page)

            Text(page.title)
                .font(.title.bold())
                .foregroundColor(themeManager.palette.screenTextPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(page.description)
                .font(.body)
                .foregroundColor(themeManager.palette.screenTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func iconBadge(for page: OnboardingPage) -> some View {
        Group {
            if page.isAssetImage {
                Image(page.icon)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            } else {
                Image(systemName: page.icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(themeManager.palette.accent)
                    .padding(36)
            }
        }
        .frame(width: 180, height: 180)
        .background(
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .overlay(
            Circle()
                .stroke(themeManager.palette.accent, lineWidth: 4)
        )
        .accessibilityHidden(true)
    }

    private func finish() {
        hapticsManager.medium()
        withAnimation { isPresented = false }
    }
}
