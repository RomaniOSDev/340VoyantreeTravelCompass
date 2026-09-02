import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    @State private var showForm = false
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showTutorial = false
    @State private var query = ""
    @State private var filter: WishlistFilter = .all
    @State private var sort: WishlistSort = .date

    private var nextTrip: Destination? {
        let upcoming = store.destinations.filter { !$0.visited }
        if let current = upcoming.first(where: \.isHappeningNow) {
            return current
        }
        return upcoming
            .filter { $0.daysUntilStart >= 0 }
            .sorted { $0.date < $1.date }
            .first
            ?? upcoming.sorted { $0.date < $1.date }.first
    }

    private var visibleDestinations: [Destination] {
        var items = store.destinations
        switch filter {
        case .all: break
        case .upcoming: items = items.filter { !$0.visited }
        case .visited: items = items.filter(\.visited)
        }
        if !query.isEmpty {
            items = items.filter { matches($0, query: query) }
        }
        switch sort {
        case .date:
            items.sort { $0.date < $1.date }
        case .name:
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .country:
            items.sort { $0.country.localizedCaseInsensitiveCompare($1.country) == .orderedAscending }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if let nextTrip, query.isEmpty, filter != .visited {
                        countdownCard(nextTrip)
                    }
                    filterBar
                    if store.destinations.isEmpty {
                        emptyState
                    } else if visibleDestinations.isEmpty {
                        TicketCard {
                            Text(query.isEmpty ? "No places in this filter." : "No matches for “\(query)”.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(visibleDestinations) { item in
                            NavigationLink(value: item) {
                                destinationRow(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .screenBackdrop("BgPass")
            .navigationTitle("Wishlist")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "Places, tasks, phrases")
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
            .alert("Plan Your Route", isPresented: $showTutorial) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text("Add a place, then generate a packing list and key phrases from its detail screen.")
            }
            .onAppear {
                if store.destinations.isEmpty {
                    showTutorial = true
                }
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
        .environmentObject(store)
        .dismissKeyboardOnTap()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                Image("BannerFlight")
                    .resizable()
                    .scaledToFill()
                    .ticketClip(height: 148)
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [.clear, AppTheme.background.opacity(0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(TicketShape(notchRadius: 11, cornerRadius: 14))
                        .frame(height: 70)
                    }
                HStack(alignment: .bottom, spacing: 12) {
                    CompassDial(size: 52)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ROUTE LOG")
                            .font(AppTheme.trackedLabel)
                            .tracking(1.6)
                            .foregroundColor(AppTheme.primary)
                        Text("Upcoming places")
                            .font(AppTheme.placeTitle)
                            .foregroundColor(.primary)
                    }
                }
                .padding(16)
            }
            Text("Tap a boarding pass to pack, phrase, and mark the visit.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func countdownCard(_ item: Destination) -> some View {
        NavigationLink(value: item) {
            TicketCard {
                HStack(alignment: .center, spacing: 12) {
                    CompassDial(size: 42)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NEXT BEARING")
                            .font(AppTheme.trackedLabel)
                            .tracking(1.2)
                            .foregroundColor(AppTheme.primary)
                        Text(item.name)
                            .font(AppTheme.placeTitle)
                        Text(item.country)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(item.dateRangeText)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text(item.countdownText)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.trailing)
                        Text("\(item.durationDays)d")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WishlistFilter.allCases) { option in
                        CompassChip(title: option.rawValue, selected: filter == option) {
                            filter = option
                        }
                    }
                }
            }
            Menu {
                ForEach(WishlistSort.allCases) { option in
                    Button(option.rawValue) { sort = option }
                }
            } label: {
                Label("Sort by \(sort.rawValue.lowercased())", systemImage: "arrow.up.arrow.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.primary)
            }
            .frame(minHeight: 44, alignment: .leading)
        }
    }

    private var emptyState: some View {
        TicketCard {
            VStack(spacing: 12) {
                CompassDial(size: 56)
                Text("Start Your Journey")
                    .font(AppTheme.placeTitle)
                Text("Add the first destination you want to stand in.")
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

    private func destinationRow(_ item: Destination) -> some View {
        TicketCard {
            HStack(alignment: .top, spacing: 12) {
                if let cover = CoverImageStore.load(item.coverFileName) {
                    Image(uiImage: cover)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(TicketShape(notchRadius: 6, cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(AppTheme.placeTitle)
                        .foregroundColor(.primary)
                    Text(item.country.uppercased())
                        .font(AppTheme.trackedLabel)
                        .tracking(1.1)
                        .foregroundColor(.secondary)
                    Text(item.dateRangeText)
                        .font(.caption.monospaced())
                        .foregroundColor(AppTheme.primary)
                    if !query.isEmpty, let hint = matchHint(item, query: query) {
                        Text(hint)
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                            .lineLimit(1)
                    } else if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: item.visited ? "checkmark.seal.fill" : "airplane")
                        .foregroundColor(item.visited ? AppTheme.accent : AppTheme.primary)
                    Text(item.visited ? "Visited" : "Open")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func matches(_ item: Destination, query: String) -> Bool {
        let fields = [item.name, item.country, item.notes, item.journal, item.climate]
        if fields.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
            return true
        }
        if store.tripTasks.contains(where: { $0.destinationId == item.id && $0.title.localizedCaseInsensitiveContains(query) }) {
            return true
        }
        if store.phrases.contains(where: {
            $0.destinationId == item.id &&
            ($0.original.localizedCaseInsensitiveContains(query) || $0.translation.localizedCaseInsensitiveContains(query))
        }) {
            return true
        }
        if store.itineraryDays.contains(where: {
            $0.destinationId == item.id &&
            ($0.title.localizedCaseInsensitiveContains(query) || $0.notes.localizedCaseInsensitiveContains(query))
        }) {
            return true
        }
        return false
    }

    private func matchHint(_ item: Destination, query: String) -> String? {
        if let task = store.tripTasks.first(where: { $0.destinationId == item.id && $0.title.localizedCaseInsensitiveContains(query) }) {
            return "Task: \(task.title)"
        }
        if let phrase = store.phrases.first(where: {
            $0.destinationId == item.id &&
            ($0.original.localizedCaseInsensitiveContains(query) || $0.translation.localizedCaseInsensitiveContains(query))
        }) {
            return "Phrase: \(phrase.original)"
        }
        if let day = store.itineraryDays.first(where: {
            $0.destinationId == item.id &&
            ($0.title.localizedCaseInsensitiveContains(query) || $0.notes.localizedCaseInsensitiveContains(query))
        }) {
            return "Day \(day.dayIndex): \(day.title)"
        }
        return nil
    }
}
