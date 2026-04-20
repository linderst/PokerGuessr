import SwiftUI

struct PlayersSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager

    @Binding var players: [Player]
    @Binding var newPlayerName: String
    
    @State private var isEditing = false

    private let rowHeight: CGFloat = 40
    private let reservedRows: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: - Header (Bearbeiten immer im Layout, nur sichtbar wenn nötig)
            HStack {
                Text("Spieler")
                    .font(.headline)
                    .foregroundColor(themeManager.palette.screenTextPrimary)

                Spacer()

                Button {
                    withAnimation { isEditing.toggle() }
                    hapticsManager.light()
                } label: {
                    Text(isEditing ? "Fertig" : "Bearbeiten")
                        .foregroundColor(.white)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(themeManager.palette.accent)
                        .clipShape(Capsule())
                }
                .opacity(players.isEmpty ? 0 : 1)
                .disabled(players.isEmpty)
            }
            .padding(.horizontal)

            // MARK: - Eingabe
            HStack(spacing: 10) {
                ThemedTextField(
                    text: $newPlayerName,
                    placeholder: "Spielername...",
                    textColor: UIColor(themeManager.palette.cardTextPrimary),
                    placeholderColor: UIColor(themeManager.palette.cardTextSecondary),
                    cursorColor: UIColor(themeManager.palette.accent)
                )
                .frame(height: 24)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(themeManager.palette.cardBackground.opacity(0.8))
                .cornerRadius(12)

                Button {
                    let trimmed = newPlayerName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        players.append(Player(name: trimmed))
                        newPlayerName = ""
                        hapticsManager.light()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(themeManager.palette.accent)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)

            // MARK: - Spielerliste (jede Karte mit eigenem Background)
            VStack(spacing: 8) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(themeManager.palette.accent)
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }

                        Text(player.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(themeManager.palette.cardTextPrimary)

                        Spacer()

                        if isEditing {
                            Button {
                                withAnimation {
                                    players.removeAll { $0.id == player.id }
                                    if players.isEmpty { isEditing = false }
                                }
                                hapticsManager.light()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.footnote.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.red.opacity(0.85))
                                    .clipShape(Circle())
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeManager.palette.cardBackground.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: themeManager.palette.border.opacity(0.25), radius: 4, y: 2)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .frame(height: CGFloat(reservedRows) * (rowHeight + 8), alignment: .top)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: players)
            .animation(.easeInOut(duration: 0.2), value: isEditing)
        }
    }
}
