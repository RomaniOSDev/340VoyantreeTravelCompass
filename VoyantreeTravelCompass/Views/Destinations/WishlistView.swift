import SwiftUI

struct WishlistView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showForm = false
    @State private var query = ""
    @State private var filter: WishlistFilter = .all
    @State private var sort: WishlistSort = .date

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
        ZStack {
            Color.clear
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
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
            .clearScrollBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackdrop("BgPass")
        .navigationTitle("Trips")
        .searchable(text: $query, prompt: "Places, tasks, phrases")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .sheet(isPresented: $showForm) {
            DestinationFormView()
                .environmentObject(store)
        }
        .dismissKeyboardOnTap()
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
                Text("No trips saved")
                    .font(AppTheme.placeTitle)
                Text("Create a trip, pin walking stops, and return to Next Bearing.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
                    Text("\(store.stops(for: item.id).count) stops · \(item.scenario.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                    Image(systemName: item.visited ? "checkmark.seal.fill" : "location.north.fill")
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
            ($0.original.localizedCaseInsensitiveContains(query)
             || $0.translation.localizedCaseInsensitiveContains(query)
             || $0.transliteration.localizedCaseInsensitiveContains(query))
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
            ($0.original.localizedCaseInsensitiveContains(query)
             || $0.translation.localizedCaseInsensitiveContains(query)
             || $0.transliteration.localizedCaseInsensitiveContains(query))
        }) {
            return "Phrase: \(phrase.original)"
        }
        if let stop = store.itineraryDays.first(where: {
            $0.destinationId == item.id &&
            ($0.title.localizedCaseInsensitiveContains(query) || $0.notes.localizedCaseInsensitiveContains(query))
        }) {
            return "Stop \(stop.stopIndex): \(stop.title)"
        }
        return nil
    }
}
