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

            // MARK: - Spielerliste (fixer Platz, kein Rahmen)
            VStack(spacing: 0) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 10) {
                        Text("\(index + 1).")
                            .font(.subheadline.bold())
                            .foregroundColor(themeManager.palette.screenTextSecondary)
                            .frame(width: 22, alignment: .leading)

                        Text(player.name)
                            .foregroundColor(themeManager.palette.screenTextPrimary)

                        Spacer()

                        if isEditing {
                            Button {
                                withAnimation {
                                    players.removeAll { $0.id == player.id }
                                }
                                hapticsManager.light()
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red.opacity(0.9))
                            }
                        }
                    }
                    .frame(height: rowHeight)
                    .padding(.horizontal)
                }
                Spacer(minLength: 0)
            }
            .frame(height: CGFloat(reservedRows) * rowHeight, alignment: .top)
        }
    }
}
