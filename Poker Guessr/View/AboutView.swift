import SwiftUI

struct AboutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            RootBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: - App Info
                    infoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "suit.spade.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(themeManager.palette.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Poker Guessr")
                                        .font(.title3.bold())
                                        .foregroundColor(themeManager.palette.cardTextPrimary)
                                    Text("Version \(appVersion)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.palette.cardTextSecondary)
                                }
                            }
                        }
                    }

                    // MARK: - Rechtliches
                    infoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rechtliches")
                                .font(.headline)
                                .foregroundColor(themeManager.palette.cardTextPrimary)

                            linkRow(
                                title: "Datenschutzerklärung",
                                icon: "lock.shield.fill",
                                urlString: "https://pokerguessr.com/privacy"
                            )

                            Divider().background(themeManager.palette.cardTextSecondary.opacity(0.3))

                            linkRow(
                                title: "Website",
                                icon: "globe",
                                urlString: "https://pokerguessr.com"
                            )
                        }
                    }

                    // MARK: - Credits
                    infoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Credits")
                                .font(.headline)
                                .foregroundColor(themeManager.palette.cardTextPrimary)

                            Text("Entwickelt von Stefan Linder")
                                .font(.subheadline)
                                .foregroundColor(themeManager.palette.cardTextPrimary)

                            Text("© 2026 Poker Guessr")
                                .font(.caption)
                                .foregroundColor(themeManager.palette.cardTextSecondary)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Info")
        .navigationBarTitleDisplayMode(.inline)
        .foregroundColor(themeManager.palette.screenTextPrimary)
    }

    @ViewBuilder
    private func linkRow(title: String, icon: String, urlString: String) -> some View {
        Button {
            hapticsManager.light()
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(themeManager.palette.accent)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(themeManager.palette.cardTextPrimary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(themeManager.palette.cardTextSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Öffnet \(urlString) im Browser")
    }

    @ViewBuilder
    private func infoCard<Content: View>(_ content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: themeManager.palette.border.opacity(0.6), radius: 10, y: 5)
    }
}
