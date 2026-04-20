import SwiftUI

struct PlayersSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticsManager: HapticsManager

    @Binding var players: [Player]
    @Binding var newPlayerName: String
    
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Spieler")
                    .font(.headline)
                    .foregroundColor(themeManager.palette.screenTextPrimary)

                Spacer()

                if !players.isEmpty {
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
                            .shadow(color: themeManager.palette.accent.opacity(0.3), radius: 4, y: 2)
                    }
                }
            }
            .padding(.horizontal)

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

            List {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack {
                        Text("\(index + 1).")
                            .font(.subheadline.bold())
                            .foregroundColor(themeManager.palette.cardTextSecondary)

                        Text(player.name)
                            .foregroundColor(themeManager.palette.cardTextPrimary)
                    }
                    .listRowBackground(themeManager.palette.cardBackground)
                }
                .if(isEditing) { view in
                    view
                        .onMove { from, to in
                            players.move(fromOffsets: from, toOffset: to)
                            hapticsManager.light()
                        }
                        .onDelete { indexSet in
                            players.remove(atOffsets: indexSet)
                            hapticsManager.light()
                        }
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(height: 3 * 48)
            .background(themeManager.palette.cardBackground.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
            .opacity(players.isEmpty ? 0 : 1)
        }
    }
}
