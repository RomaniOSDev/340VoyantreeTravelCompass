import SwiftUI

struct PhrasesView: View {
    @EnvironmentObject private var store: AppDataStore
    let destinationId: UUID
    @State private var showForm = false
    @State private var editing: PhraseItem?
    @State private var query = ""
    @State private var categoryFilter: String = "All"

    private var allItems: [PhraseItem] {
        store.phrases.filter { $0.destinationId == destinationId }
    }

    private var categoryOptions: [String] {
        ["All"] + PhraseCategory.allCases.map(\.rawValue)
    }

    private var items: [PhraseItem] {
        var list = allItems
        if categoryFilter != "All" {
            list = list.filter { $0.category == categoryFilter }
        }
        if query.isEmpty { return list }
        return list.filter {
            $0.original.localizedCaseInsensitiveContains(query) ||
            $0.translation.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image("BannerPhrases")
                    .resizable()
                    .scaledToFill()
                    .ticketClip(height: 120)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categoryOptions, id: \.self) { option in
                            CompassChip(title: option, selected: categoryFilter == option) {
                                categoryFilter = option
                            }
                        }
                    }
                }

                if allItems.isEmpty {
                    TicketCard {
                        VStack(spacing: 10) {
                            Image(systemName: "globe")
                                .font(.system(size: 36))
                                .foregroundColor(AppTheme.primary)
                            Text("Add your first destination")
                                .font(.headline)
                            Text("Save useful lines before you travel.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else if items.isEmpty {
                    TicketCard {
                        Text("No phrases in this filter.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(items) { item in
                        TicketCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.category)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(AppTheme.primary)
                                Text(item.original)
                                    .font(AppTheme.placeTitle)
                                Text(item.translation)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Button("Edit") { editing = item }
                                    Spacer()
                                    Button("Delete", role: .destructive) {
                                        store.deletePhrase(item.id)
                                    }
                                }
                            }
                        }
                    }
                }

                if !allItems.isEmpty {
                    NavigationLink {
                        PhrasePracticeView(items: items.isEmpty ? allItems : items)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(AppTheme.goldLift)
                                Image(systemName: "rectangle.on.rectangle.angled")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(AppTheme.background)
                            }
                            .frame(width: 36, height: 36)
                            Text("Practice cards")
                                .font(.headline)
                                .foregroundColor(AppTheme.primary)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.primary.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            TicketShape(notchRadius: 8, cornerRadius: 16)
                                .fill(AppTheme.surface.opacity(0.92))
                                .overlay {
                                    TicketShape(notchRadius: 8, cornerRadius: 16)
                                        .stroke(AppTheme.goldLift, lineWidth: 1.4)
                                }
                        }
                    }
                    .buttonStyle(GoldPressStyle())
                    .frame(minHeight: 44)
                }

                GoldActionButton(title: "Add phrase", systemImage: "plus") {
                    showForm = true
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgPass")
        .navigationTitle("Phrases")
        .searchable(text: $query)
        .scrollDismissesKeyboard(.immediately)
        .dismissKeyboardOnTap()
        .sheet(isPresented: $showForm) {
            PhraseFormView(destinationId: destinationId)
                .environmentObject(store)
        }
        .sheet(item: $editing) { item in
            PhraseFormView(destinationId: destinationId, existing: item)
                .environmentObject(store)
        }
    }
}
