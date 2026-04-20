import SwiftUI

struct PlayersSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager

    @Binding var players: [Player]
    @Binding var newPlayerName: String
    
    @State private var isEditing = false

    private let rowHeight: CGFloat = 44
    private let rowSpacing: CGFloat = 8
    private let reservedRows: Int = 2

    private var listHeight: CGFloat {
        CGFloat(reservedRows) * rowHeight + CGFloat(reservedRows - 1) * rowSpacing
    }

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

            // MARK: - Spielerliste (scrollbar, auto-scroll zum letzten Eintrag)
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: rowSpacing) {
                        ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                            playerRow(index: index, player: player)
                                .id(player.id)
                        }
                    }
                    .padding(.vertical, rowSpacing / 2)
                }
                .onChange(of: players.count) { oldValue, newValue in
                    if newValue > oldValue, let last = players.last {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(height: listHeight)
            .padding(.horizontal)
            .opacity(players.isEmpty ? 0 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: players)
            .animation(.easeInOut(duration: 0.2), value: isEditing)
        }
    }

    // MARK: - Player Row
    @ViewBuilder
    private func playerRow(index: Int, player: Player) -> some View {
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
                .lineLimit(1)

            Spacer()

            if isEditing {
                HStack(spacing: 6) {
                    Button {
                        move(from: index, by: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.footnote.bold())
                            .frame(width: 28, height: 28)
                            .foregroundColor(index == 0
                                             ? themeManager.palette.cardTextSecondary.opacity(0.4)
                                             : themeManager.palette.accent)
                            .background(
                                Circle()
                                    .stroke(themeManager.palette.accent.opacity(index == 0 ? 0.2 : 0.6), lineWidth: 1)
                            )
                    }
                    .disabled(index == 0)

                    Button {
                        move(from: index, by: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.footnote.bold())
                            .frame(width: 28, height: 28)
                            .foregroundColor(index == players.count - 1
                                             ? themeManager.palette.cardTextSecondary.opacity(0.4)
                                             : themeManager.palette.accent)
                            .background(
                                Circle()
                                    .stroke(themeManager.palette.accent.opacity(index == players.count - 1 ? 0.2 : 0.6), lineWidth: 1)
                            )
                    }
                    .disabled(index == players.count - 1)

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
                            .frame(width: 28, height: 28)
                            .background(Color.red.opacity(0.85))
                            .clipShape(Circle())
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: rowHeight)
        .background(themeManager.palette.cardBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: themeManager.palette.border.opacity(0.2), radius: 3, y: 1)
    }

    private func move(from index: Int, by offset: Int) {
        let newIndex = index + offset
        guard newIndex >= 0, newIndex < players.count else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            players.swapAt(index, newIndex)
        }
        hapticsManager.light()
    }
}
