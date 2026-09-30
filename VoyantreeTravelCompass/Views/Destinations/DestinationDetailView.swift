import MapKit
import SwiftUI

struct DestinationDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let destinationId: UUID
    @State private var showEdit = false
    @State private var confirmDelete = false
    @State private var showJournal = false
    @State private var journalMarksVisited = false
    @State private var region = RouteMapRegion.fitting([])

    private var destination: Destination? {
        store.destinations.first { $0.id == destinationId }
    }

    private var stops: [RouteStop] {
        store.stops(for: destinationId)
    }

    var body: some View {
        Group {
            if let destination {
                ZStack {
                    Color.clear
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            DestinationCover(fileName: destination.coverFileName, fallbackAsset: "BannerPack", height: 150)

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
                                    Text("Kit: \(destination.scenario.rawValue)")
                                        .font(.subheadline)
                                    Text("Phrases: \(PhraseLanguage(rawValue: destination.phraseLanguage)?.title ?? destination.phraseLanguage)")
                                        .font(.subheadline)
                                    Text("Time: \(destination.timezone)")
                                        .font(.subheadline)
                                    if !destination.notes.isEmpty {
                                        Text(destination.notes)
                                            .font(.body)
                                    }
                                }
                            }

                            if !stops.filter(\.isPinned).isEmpty {
                                Map(coordinateRegion: $region, annotationItems: stops.filter(\.isPinned)) { stop in
                                    MapMarker(coordinate: stop.coordinate, tint: Color("AppPrimary"))
                                }
                                .frame(height: 180)
                                .clipShape(TicketShape(notchRadius: 11, cornerRadius: 14))
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

                            NavigationLink {
                                ItineraryView(destinationId: destination.id)
                            } label: {
                                linkLabel("Route stops", count: stops.count, icon: "mappin.and.ellipse")
                            }

                            NavigationLink {
                                TripTasksView(destinationId: destination.id)
                            } label: {
                                linkLabel("Packing kit", count: store.tripTasks.filter { $0.destinationId == destination.id }.count, icon: "checklist")
                            }

                            NavigationLink {
                                PhrasesView(destinationId: destination.id)
                            } label: {
                                linkLabel("Key phrases", count: store.phrases.filter { $0.destinationId == destination.id }.count, icon: "text.bubble")
                            }

                            Button {
                                journalMarksVisited = false
                                showJournal = true
                            } label: {
                                linkLabel(
                                    "Visit journal",
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
                    .clearScrollBackground()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .screenBackdrop("BgPass")
                .navigationTitle("Place")
                .onAppear {
                    region = RouteMapRegion.fitting(stops)
                }
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
