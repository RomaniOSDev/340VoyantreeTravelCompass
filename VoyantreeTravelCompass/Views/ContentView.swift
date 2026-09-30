import CoreLocation
import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    @StateObject private var locator = CompassLocationManager()
    @State private var showForm = false
    @State private var showSettings = false
    @State private var showStats = false

    private var trip: Destination? { store.currentTrip }

    private var nextStop: RouteStop? {
        guard let trip else { return nil }
        return store.nextStop(for: trip.id, from: locator.userCoordinate)
    }

    private var bearing: Double? {
        guard let nextStop, nextStop.isPinned else { return nil }
        if let user = locator.userCoordinate {
            return GeoMath.bearing(from: user, to: nextStop.coordinate)
        }
        if let previous = previousPinned(before: nextStop) {
            return GeoMath.bearing(from: previous.coordinate, to: nextStop.coordinate)
        }
        return nil
    }

    private var distanceMeters: CLLocationDistance? {
        guard let nextStop, nextStop.isPinned, let user = locator.userCoordinate else { return nil }
        return GeoMath.distance(user, nextStop.coordinate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        liveCompassCard
                        if let trip {
                            tripDayCard(trip)
                            if let nextStop {
                                nextStopCard(nextStop)
                            } else {
                                missingStopsCard(trip)
                            }
                            packingCard(trip)
                            phrasesCard(trip)
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenBackdrop("BgPass")
            .navigationTitle("Next Bearing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityIdentifier("open_settings")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        WishlistView()
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityIdentifier("open_wishlist")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityIdentifier("open_stats")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityIdentifier("add_destination")
                }
            }
            .navigationDestination(for: Destination.self) { item in
                DestinationDetailView(destinationId: item.id)
            }
            .sheet(isPresented: $showForm) {
                DestinationFormView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showStats) {
                NavigationStack {
                    StatsView(showsDoneButton: true)
                }
                .tint(AppTheme.primary)
                .preferredColorScheme(.dark)
                .environmentObject(store)
            }
            .onAppear {
                locator.requestAndStart()
            }
            .onDisappear {
                locator.stopUpdates()
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
        .environmentObject(store)
        .dismissKeyboardOnTap()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY")
                .font(AppTheme.trackedLabel)
                .tracking(1.6)
                .foregroundColor(AppTheme.primary)
            Text("Point the gold needle at the next walking stop.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var liveCompassCard: some View {
        TicketCard {
            VStack(spacing: 16) {
                LiveBearingCompass(
                    heading: locator.heading,
                    bearing: bearing,
                    size: 200
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                if locator.isDenied {
                    Text("Location is off. Enable it to lock the needle on your next stop.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .frame(minHeight: 44)
                } else if !locator.isAuthorized {
                    GoldActionButton(title: "Enable live compass", systemImage: "location.north.line") {
                        locator.requestAndStart()
                    }
                } else if locator.location == nil {
                    Text("Acquiring GPS… keep the phone level.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let distanceMeters, let nextStop {
                    Text(nextStop.title)
                        .font(AppTheme.placeTitle)
                        .multilineTextAlignment(.center)
                    Text("\(GeoMath.formatDistance(distanceMeters)) · \(GeoMath.formatWalking(distanceMeters))")
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundColor(AppTheme.primary)
                    if let heading = locator.heading, let bearing {
                        Text("Bearing \(Int(bearing.rounded()))° · heading \(Int(heading.rounded()))°")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    } else if !locator.headingAvailable {
                        Text("Heading unavailable on this device. Distance is live.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else if bearing != nil {
                    Text("No GPS fix yet. Needle shows the route bearing between pinned stops.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Pin a stop on the route to give the compass a target.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func tripDayCard(_ trip: Destination) -> some View {
        NavigationLink(value: trip) {
            TicketCard {
                HStack(alignment: .center, spacing: 12) {
                    CompassDial(size: 42)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.isHappeningNow ? "CURRENT TRIP · DAY \(trip.currentTripDay)" : "NEXT TRIP")
                            .font(AppTheme.trackedLabel)
                            .tracking(1.2)
                            .foregroundColor(AppTheme.primary)
                        Text(trip.name)
                            .font(AppTheme.placeTitle)
                        Text("\(trip.country) · \(trip.scenario.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(trip.countdownText)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func nextStopCard(_ stop: RouteStop) -> some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("NEXT STOP")
                    .font(AppTheme.trackedLabel)
                    .tracking(1.2)
                    .foregroundColor(AppTheme.primary)
                Text(stop.title)
                    .font(AppTheme.placeTitle)
                if !stop.notes.isEmpty {
                    Text(stop.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(String(format: "Stop %d · %.5f, %.5f", stop.stopIndex, stop.latitude, stop.longitude))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                if let previous = previousPinned(before: stop) {
                    let meters = GeoMath.distance(previous.coordinate, stop.coordinate)
                    Text("From \(previous.title): \(GeoMath.formatDistance(meters)) · \(GeoMath.formatWalking(meters))")
                        .font(.caption)
                        .foregroundColor(AppTheme.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func missingStopsCard(_ trip: Destination) -> some View {
        NavigationLink {
            ItineraryView(destinationId: trip.id)
        } label: {
            TicketCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NO PINNED STOPS")
                        .font(AppTheme.trackedLabel)
                        .tracking(1.2)
                        .foregroundColor(AppTheme.primary)
                    Text("Drop map pins so the compass has a live target.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func packingCard(_ trip: Destination) -> some View {
        let open = store.openPacking(for: trip.id)
        return NavigationLink {
            TripTasksView(destinationId: trip.id)
        } label: {
            TicketCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("STILL TO PACK")
                        .font(AppTheme.trackedLabel)
                        .tracking(1.2)
                        .foregroundColor(AppTheme.primary)
                    if open.isEmpty {
                        Text("Packing kit is clear for this trip.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(open.prefix(3)) { task in
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .foregroundColor(AppTheme.primary)
                                Text(task.title)
                                    .font(.subheadline)
                            }
                        }
                        if open.count > 3 {
                            Text("+\(open.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func phrasesCard(_ trip: Destination) -> some View {
        let lines = store.phrasesForToday(destination: trip)
        return NavigationLink {
            PhrasesView(destinationId: trip.id)
        } label: {
            TicketCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("PHRASES FOR THIS DAY")
                        .font(AppTheme.trackedLabel)
                        .tracking(1.2)
                        .foregroundColor(AppTheme.primary)
                    if lines.isEmpty {
                        Text("No phrase pack on this trip yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(lines) { phrase in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phrase.original)
                                    .font(.headline)
                                if !phrase.transliteration.isEmpty {
                                    Text(phrase.transliteration)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.primary)
                                }
                                Text(phrase.translation)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        TicketCard {
            VStack(spacing: 12) {
                CompassDial(size: 56)
                Text("No active trip")
                    .font(AppTheme.placeTitle)
                Text("Add a destination with pinned walking stops to give the compass a bearing.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                GoldActionButton(title: "Add destination", systemImage: "plus") {
                    showForm = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private func previousPinned(before stop: RouteStop) -> RouteStop? {
        store.stops(for: stop.destinationId)
            .filter(\.isPinned)
            .last { $0.stopIndex < stop.stopIndex }
    }
}
