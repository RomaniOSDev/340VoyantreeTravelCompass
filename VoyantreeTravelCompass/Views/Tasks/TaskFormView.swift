import SwiftUI

struct TaskFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let destinationId: UUID
    var existing: TripTask?

    @State private var title = ""
    @State private var category = TaskCategory.packing.rawValue
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    if let error {
                        Text(error).font(.caption).foregroundColor(.red)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.rawValue) { item in
                            Text(item.rawValue).tag(item.rawValue)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle(existing == nil ? "New task" : "Edit task")
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
                    title = existing.title
                    category = existing.category
                }
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            error = "Task title cannot be blank."
            return
        }
        let task = TripTask(
            id: existing?.id ?? UUID(),
            destinationId: destinationId,
            title: trimmed,
            completed: existing?.completed ?? false,
            category: category
        )
        store.upsertTask(task)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
