import CoreLocation
import MapKit
import SwiftUI

struct ItineraryView: View {
    @EnvironmentObject private var store: AppDataStore
    let destinationId: UUID
    @State private var showForm = false
    @State private var editing: RouteStop?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private var destination: Destination? {
        store.destinations.first { $0.id == destinationId }
    }

    private var stops: [RouteStop] {
        store.stops(for: destinationId)
    }

    var body: some View {
        ZStack {
            Color.clear
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let destination {
                        TicketCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(destination.durationDays) day trip · \(stops.count) stops")
                                    .font(.headline)
                                Text(destination.dateRangeText)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.primary)
                                Text("Pan the map, then drop pins in walking order.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Map(coordinateRegion: $region, annotationItems: stops.filter(\.isPinned)) { stop in
                        MapAnnotation(coordinate: stop.coordinate) {
                            VStack(spacing: 2) {
                                Text("\(stop.stopIndex)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(AppTheme.background)
                                    .padding(6)
                                    .background(Circle().fill(AppTheme.goldLift))
                                Text(stop.title)
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.surface.opacity(0.92))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(height: 240)
                    .clipShape(TicketShape(notchRadius: 11, cornerRadius: 14))
                    .overlay {
                        TicketShape(notchRadius: 11, cornerRadius: 14)
                            .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1.1)
                    }

                    if stops.isEmpty {
                        TicketCard {
                            VStack(spacing: 10) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppTheme.primary)
                                Text("No walking stops")
                                    .font(.headline)
                                Text("Pin the next doorway, plaza, or trailhead so the compass has a target.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                            TicketCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("STOP \(stop.stopIndex)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.primary)
                                    Text(stop.title)
                                        .font(.headline)
                                    if !stop.notes.isEmpty {
                                        Text(stop.notes)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    if stop.isPinned {
                                        Text(String(format: "%.5f, %.5f", stop.latitude, stop.longitude))
                                            .font(.caption.monospacedDigit())
                                            .foregroundColor(.secondary)
										if index > 0, stops[index - 1].isPinned {
                                            Text(legText(from: stops[index - 1], to: stop))
                                                .font(.caption)
                                                .foregroundColor(AppTheme.primary)
                                        }
                                    } else {
                                        Text("Not pinned yet")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    HStack {
                                        Button("Edit") { editing = stop }
                                        Spacer()
                                        Button("Delete", role: .destructive) {
                                            store.deleteStop(stop.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GoldActionButton(title: "Add stop", systemImage: "plus") {
                        showForm = true
                    }
                }
                .padding(18)
            }
            .clearScrollBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackdrop("BgPass")
        .navigationTitle("Route stops")
        .onAppear { refitMap() }
        .onChange(of: stops.count) { _ in refitMap() }
        .sheet(isPresented: $showForm, onDismiss: refitMap) {
            RouteStopFormView(
                destinationId: destinationId,
                suggestedIndex: (stops.map(\.stopIndex).max() ?? 0) + 1,
                fallbackCoordinate: stops.last(where: \.isPinned)?.coordinate
            )
            .environmentObject(store)
        }
        .sheet(item: $editing, onDismiss: refitMap) { stop in
            RouteStopFormView(destinationId: destinationId, existing: stop)
                .environmentObject(store)
        }
    }

    private func refitMap() {
        region = RouteMapRegion.fitting(stops, fallback: stops.first(where: \.isPinned)?.coordinate)
    }

    private func legText(from previous: RouteStop, to stop: RouteStop) -> String {
        let meters = GeoMath.distance(previous.coordinate, stop.coordinate)
        return "From previous: \(GeoMath.formatDistance(meters)) · \(GeoMath.formatWalking(meters))"
    }
}

private struct RouteStopFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let destinationId: UUID
    var existing: RouteStop?
    var suggestedIndex = 1
    var fallbackCoordinate: CLLocationCoordinate2D?

    @State private var stopIndex = 1
    @State private var title = ""
    @State private var notes = ""
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Stop") {
                    Stepper("Order \(stopIndex)", value: $stopIndex, in: 1...40)
                    TextField("Title", text: $title)
                    if let error {
                        Text(error).font(.caption).foregroundColor(.red)
                    }
                    TextField("Walking note", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Map pin") {
                    RoutePinPicker(
                        latitude: $latitude,
                        longitude: $longitude,
                        fallback: fallbackCoordinate ?? existing?.coordinate
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle(existing == nil ? "New stop" : "Edit stop")
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
                    stopIndex = existing.stopIndex
                    title = existing.title
                    notes = existing.notes
                    latitude = existing.latitude
                    longitude = existing.longitude
                } else {
                    stopIndex = suggestedIndex
                    if let fallbackCoordinate {
                        latitude = fallbackCoordinate.latitude
                        longitude = fallbackCoordinate.longitude
                    }
                }
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            error = "Give this stop a title."
            return
        }
        if abs(latitude) < 0.0001 && abs(longitude) < 0.0001 {
            error = "Drop a map pin before saving."
            return
        }
        store.upsertStop(
            RouteStop(
                id: existing?.id ?? UUID(),
                destinationId: destinationId,
                stopIndex: stopIndex,
                title: trimmed,
                notes: notes,
                latitude: latitude,
                longitude: longitude
            )
        )
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
