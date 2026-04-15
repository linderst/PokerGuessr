import SwiftUI

struct CategorySheet: View {
    
    @Binding var selectedCategory: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var searchText = ""
    
    var filteredCategories: [QuestionCategory] {
        if searchText.isEmpty { return QuestionCategory.allCases }
        return QuestionCategory.allCases.filter { $0.rawValue.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RootBackground()
                
                VStack(spacing: 16) {
                    
                    // MARK: - Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(
                                themeManager.currentTheme == .midnightPurple
                                ? .white
                                : .black
                            )

                        TextField("Kategorie suchen…", text: $searchText)
                            .foregroundColor(themeManager.palette.cardTextPrimary)
                            .environment(\.colorScheme, themeManager.currentTheme == .midnightPurple ? .dark : .light)
                    }
                    .padding()
                    .background(themeManager.palette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: themeManager.palette.border.opacity(0.4), radius: 6, y: 4)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    
                    // MARK: - Category List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredCategories, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat.rawValue
                                    dismiss()
                                } label: {
                                    HStack(spacing: 14) {
                                        
                                        // Kategorie-Icon
                                        Image(systemName: icon(for: cat))
                                            .foregroundColor(themeManager.palette.accent)
                                            .font(.system(size: 22, weight: .semibold))
                                            .frame(width: 32)
                                        
                                        // Kategoriename
                                        Text(cat.rawValue)
                                            .foregroundColor(themeManager.palette.cardTextPrimary)
                                            .font(.system(size: 18, weight: .medium))
                                        
                                        Spacer()
                                        
                                        // Auswahlindikator
                                        if selectedCategory == cat.rawValue {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(themeManager.palette.accent)
                                                .font(.system(size: 22, weight: .bold))
                                                .transition(.scale)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(themeManager.palette.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Kategorie wählen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Kategorie Icons
    private func icon(for category: QuestionCategory) -> String {
        switch category {
        case .alle: return "square.grid.2x2"
        case .sport: return "figure.run"
        case .geografie: return "globe.europe.africa"
        case .mensch: return "person.crop.circle"
        case .wissenschaft: return "atom"
        case .technik: return "gearshape.fill"
        case .essenTrinken: return "fork.knife"
        case .geschichte: return "book.closed.fill"
        case .sprachen: return "textformat.alt"
        case .popkultur: return "music.note"
        case .allgemeinwissen: return "lightbulb"
        case .menschKoerper: return "person.crop.circle"
        }
    }
}
