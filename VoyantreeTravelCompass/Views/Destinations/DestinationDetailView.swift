import SwiftUI

struct DestinationDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let destinationId: UUID
    @State private var showEdit = false
    @State private var confirmDelete = false
    @State private var showJournal = false
    @State private var journalMarksVisited = false

    private var destination: Destination? {
        store.destinations.first { $0.id == destinationId }
    }

    var body: some View {
        Group {
            if let destination {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DestinationCover(fileName: destination.coverFileName, fallbackAsset: "BannerPack", height: 150)
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

                        TicketCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DESTINATION")
                                    .font(AppTheme.trackedLabel)
                                    .tracking(1.4)
                                    .foregroundColor(AppTheme.primary)
                                Text(destination.name)
                                    .font(AppTheme.displayTitle)
                                Text(destination.country.uppercased())
                                    .font(AppTheme.trackedLabel)
                                    .tracking(1.1)
                                    .foregroundColor(.secondary)
                                Text(destination.dateRangeText)
                                    .font(.subheadline.monospaced())
                                    .foregroundColor(AppTheme.primary)
                                Text("\(destination.durationDays) days · \(destination.countdownText)")
                                    .font(.subheadline)
                                Text("Climate: \(destination.climate)")
                                    .font(.subheadline)
                                Text("Time: \(destination.timezone)")
                                    .font(.subheadline)
                                if !destination.notes.isEmpty {
                                    Text(destination.notes)
                                        .font(.body)
                                }
                            }
                        }

                        GoldActionButton(
                            title: destination.visited ? "Mark as upcoming" : "Mark as visited",
                            systemImage: "checkmark.circle"
                        ) {
                            if destination.visited {
                                store.markVisited(destination.id)
                            } else {
                                journalMarksVisited = true
                                showJournal = true
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }

                        GoldActionButton(title: "Prepare packing & phrases", systemImage: "suitcase.fill") {
                            store.prepareTrip(for: destination)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        .accessibilityIdentifier("prepare_trip")

                        NavigationLink {
                            TripTasksView(destinationId: destination.id)
                        } label: {
                            linkLabel("Packing tasks", count: store.tripTasks.filter { $0.destinationId == destination.id }.count, icon: "checklist")
                        }

                        NavigationLink {
                            PhrasesView(destinationId: destination.id)
                        } label: {
                            linkLabel("Key phrases", count: store.phrases.filter { $0.destinationId == destination.id }.count, icon: "text.bubble")
                        }

                        NavigationLink {
                            ItineraryView(destinationId: destination.id)
                        } label: {
                            linkLabel("Itinerary", count: store.itineraryDays.filter { $0.destinationId == destination.id }.count, icon: "calendar")
                        }

                        Button {
                            journalMarksVisited = false
                            showJournal = true
                        } label: {
                            linkLabel(
                                destination.journal.isEmpty ? "Visit journal" : "Visit journal",
                                count: destination.journal.isEmpty ? 0 : 1,
                                icon: "book"
                            )
                        }
                        .buttonStyle(.plain)

                        if !destination.journal.isEmpty {
                            TicketCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Journal")
                                        .font(.headline)
                                    Text(destination.journal)
                                        .font(.body)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        Button("Delete destination", role: .destructive) {
                            confirmDelete = true
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(18)
                }
                .screenBackdrop("BgPass")
                .navigationTitle("Place")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") { showEdit = true }
                    }
                }
                .sheet(isPresented: $showEdit) {
                    DestinationFormView(existing: destination)
                        .environmentObject(store)
                }
                .sheet(isPresented: $showJournal) {
                    VisitJournalView(destinationId: destination.id, marksVisitedOnSave: journalMarksVisited)
                        .environmentObject(store)
                }
                .alert("Delete this place?", isPresented: $confirmDelete) {
                    Button("Delete", role: .destructive) {
                        store.deleteDestination(destination.id)
                    }
                    Button("Cancel", role: .cancel) { }
                }
            } else {
                Text("This place is no longer in the list.")
                    .foregroundColor(.secondary)
                    .screenBackdrop("BgPass")
            }
        }
    }

    private func linkLabel(_ title: String, count: Int, icon: String) -> some View {
        TicketCard {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        TicketShape(notchRadius: 4, cornerRadius: 6)
                            .fill(AppTheme.primary.opacity(0.2))
                    )
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}
