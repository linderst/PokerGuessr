import SwiftUI

struct PlayersSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager

    @Binding var players: [Player]
    @Binding var newPlayerName: String
    
    @State private var isEditing = false

    private let rowHeight: CGFloat = 44
    private let rowSpacing: CGFloat = 8
    private let reservedRows: Int = 3

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

            // MARK: - Spielerliste (scrollbar ab Spieler 4, mit Reorder im Edit-Modus)
            List {
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
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(height: rowHeight)
                    .background(themeManager.palette.cardBackground.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: themeManager.palette.border.opacity(0.2), radius: 3, y: 1)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: rowSpacing / 2, leading: 0, bottom: rowSpacing / 2, trailing: 0))
                }
                .onMove { from, to in
                    players.move(fromOffsets: from, toOffset: to)
                    hapticsManager.light()
                }
                .onDelete { indexSet in
                    players.remove(atOffsets: indexSet)
                    if players.isEmpty { isEditing = false }
                    hapticsManager.light()
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .frame(height: listHeight)
            .padding(.horizontal)
            .opacity(players.isEmpty ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: isEditing)
        }
    }
}
