import SwiftUI

struct ItineraryView: View {
    @EnvironmentObject private var store: AppDataStore
    let destinationId: UUID
    @State private var showForm = false
    @State private var editing: ItineraryDay?

    private var destination: Destination? {
        store.destinations.first { $0.id == destinationId }
    }

    private var days: [ItineraryDay] {
        store.itineraryDays
            .filter { $0.destinationId == destinationId }
            .sorted { $0.dayIndex < $1.dayIndex }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let destination {
                    TicketCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(destination.durationDays) day trip")
                                .font(.headline)
                            Text(destination.dateRangeText)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if days.isEmpty {
                    TicketCard {
                        VStack(spacing: 10) {
                            Image(systemName: "calendar")
                                .font(.system(size: 36))
                                .foregroundColor(AppTheme.primary)
                            Text("No days planned")
                                .font(.headline)
                            Text("Sketch Day 1, Day 2, and the rest of the stay.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(days) { day in
                        TicketCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Day \(day.dayIndex)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(AppTheme.primary)
                                Text(day.title)
                                    .font(.headline)
                                if !day.notes.isEmpty {
                                    Text(day.notes)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Button("Edit") { editing = day }
                                    Spacer()
                                    Button("Delete", role: .destructive) {
                                        store.deleteItineraryDay(day.id)
                                    }
                                }
                            }
                        }
                    }
                }

                GoldActionButton(title: "Add day", systemImage: "plus") {
                    showForm = true
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgPass")
        .navigationTitle("Itinerary")
        .sheet(isPresented: $showForm) {
            ItineraryDayFormView(
                destinationId: destinationId,
                suggestedIndex: (days.map(\.dayIndex).max() ?? 0) + 1
            )
            .environmentObject(store)
        }
        .sheet(item: $editing) { day in
            ItineraryDayFormView(destinationId: destinationId, existing: day)
                .environmentObject(store)
        }
    }
}

private struct ItineraryDayFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let destinationId: UUID
    var existing: ItineraryDay?
    var suggestedIndex = 1

    @State private var dayIndex = 1
    @State private var title = ""
    @State private var notes = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Day") {
                    Stepper("Day \(dayIndex)", value: $dayIndex, in: 1...30)
                    TextField("Title", text: $title)
                    if let error {
                        Text(error).font(.caption).foregroundColor(.red)
                    }
                    TextField("Plan notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle(existing == nil ? "New day" : "Edit day")
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
                    dayIndex = existing.dayIndex
                    title = existing.title
                    notes = existing.notes
                } else {
                    dayIndex = suggestedIndex
                }
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            error = "Give this day a title."
            return
        }
        store.upsertItineraryDay(
            ItineraryDay(
                id: existing?.id ?? UUID(),
                destinationId: destinationId,
                dayIndex: dayIndex,
                title: trimmed,
                notes: notes
            )
        )
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
