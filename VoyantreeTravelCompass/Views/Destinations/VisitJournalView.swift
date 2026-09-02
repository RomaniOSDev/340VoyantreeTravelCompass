import SwiftUI

struct VisitJournalView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let destinationId: UUID
    var marksVisitedOnSave: Bool

    @State private var text = ""

    private var destination: Destination? {
        store.destinations.first { $0.id == destinationId }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                } header: {
                    Text("What stood out?")
                } footer: {
                    Text("Keep packing notes, food finds, or what to do differently next time.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle("Visit journal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(marksVisitedOnSave ? "Skip" : "Cancel") {
                        if marksVisitedOnSave {
                            store.setJournal(for: destinationId, text: destination?.journal ?? "", markVisited: true)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setJournal(
                            for: destinationId,
                            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                            markVisited: marksVisitedOnSave || (destination?.visited ?? false)
                        )
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                }
            }
            .onAppear {
                text = destination?.journal ?? ""
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }
}
