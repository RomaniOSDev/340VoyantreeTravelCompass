import SwiftUI

struct PhraseFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let destinationId: UUID
    var existing: PhraseItem?

    @State private var original = ""
    @State private var translation = ""
    @State private var transliteration = ""
    @State private var language = PhraseLanguage.french.rawValue
    @State private var category = PhraseCategory.greeting.rawValue
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Phrase") {
                    TextField("Original", text: $original)
                    TextField("Transliteration", text: $transliteration)
                    TextField("English", text: $translation)
                    Picker("Language", selection: $language) {
                        ForEach(PhraseLanguage.allCases) { item in
                            Text(item.title).tag(item.rawValue)
                        }
                    }
                    Picker("Category", selection: $category) {
                        ForEach(PhraseCategory.allCases) { item in
                            Text(item.rawValue).tag(item.rawValue)
                        }
                    }
                    if let error {
                        Text(error).font(.caption).foregroundColor(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle(existing == nil ? "New phrase" : "Edit phrase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                if let existing {
                    original = existing.original
                    translation = existing.translation
                    transliteration = existing.transliteration
                    language = existing.language
                    category = existing.category
                } else if let destination = store.destinations.first(where: { $0.id == destinationId }) {
                    language = destination.phraseLanguage
                }
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }

    private func save() {
        let o = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let t = translation.trimmingCharacters(in: .whitespacesAndNewlines)
        if o.isEmpty || t.isEmpty {
            error = "Both lines are required."
            return
        }
        let item = PhraseItem(
            id: existing?.id ?? UUID(),
            destinationId: destinationId,
            original: o,
            translation: t,
            category: category,
            transliteration: transliteration.trimmingCharacters(in: .whitespacesAndNewlines),
            language: language
        )
        store.upsertPhrase(item)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
