import Foundation
import Combine
import CoreLocation

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var destinations: [Destination] = []
    @Published var tripTasks: [TripTask] = []
    @Published var phrases: [PhraseItem] = []
    @Published var itineraryDays: [RouteStop] = []
    @Published var lastViewedDestination: UUID?
    @Published var activeTripId: UUID?
    @Published var selectedLocaleID: UUID?

    private let defaults = UserDefaults.standard
    private let destinationsKey = "destinations"
    private let tasksKey = "tripTasks"
    private let phrasesKey = "phrases"
    private let itineraryKey = "itineraryDays"
    private let lastViewedKey = "lastViewedDestination"
    private let activeTripKey = "activeTripId"
    private let localeKey = "selectedLocaleID"
    private let catalogSeedKey = "catalogSeeded_v1"

    private init() {
        load()
        NotificationCenter.default.addObserver(forName: .dataReset, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.load()
            }
        }
    }

    func load() {
        destinations = decode([Destination].self, key: destinationsKey) ?? []
        tripTasks = decode([TripTask].self, key: tasksKey) ?? []
        phrases = decode([PhraseItem].self, key: phrasesKey) ?? []
        itineraryDays = decode([RouteStop].self, key: itineraryKey) ?? []
        if let raw = defaults.string(forKey: lastViewedKey) {
            lastViewedDestination = UUID(uuidString: raw)
        }
        if let raw = defaults.string(forKey: activeTripKey) {
            activeTripId = UUID(uuidString: raw)
        }
        if let raw = defaults.string(forKey: localeKey) {
            selectedLocaleID = UUID(uuidString: raw)
        }
        if destinations.isEmpty {
            seedCatalog()
        }
        destinations.filter { !$0.visited }.forEach { TripReminderScheduler.refresh(for: $0) }
    }

    func save() {
        encode(destinations, key: destinationsKey)
        encode(tripTasks, key: tasksKey)
        encode(phrases, key: phrasesKey)
        encode(itineraryDays, key: itineraryKey)
        defaults.set(lastViewedDestination?.uuidString, forKey: lastViewedKey)
        defaults.set(activeTripId?.uuidString, forKey: activeTripKey)
        defaults.set(selectedLocaleID?.uuidString, forKey: localeKey)
    }

    var currentTrip: Destination? {
        let upcoming = destinations.filter { !$0.visited }
        if let happening = upcoming.first(where: \.isHappeningNow) {
            return happening
        }
        if let active = upcoming.first(where: { $0.id == activeTripId }) {
            return active
        }
        return upcoming
            .filter { $0.daysUntilStart >= 0 }
            .sorted { $0.date < $1.date }
            .first
            ?? upcoming.sorted { $0.date < $1.date }.first
    }

    func stops(for destinationId: UUID) -> [RouteStop] {
        itineraryDays
            .filter { $0.destinationId == destinationId }
            .sorted { $0.stopIndex < $1.stopIndex }
    }

    func nextStop(for destinationId: UUID, from user: CLLocationCoordinate2D?) -> RouteStop? {
        let list = stops(for: destinationId).filter(\.isPinned)
        guard !list.isEmpty else { return nil }
        guard let user else { return list.first }
        for stop in list {
            if GeoMath.distance(user, stop.coordinate) > GeoMath.arrivalThreshold {
                return stop
            }
        }
        return list.last
    }

    func phrasesForToday(destination: Destination) -> [PhraseItem] {
        let all = phrases.filter { $0.destinationId == destination.id }
        guard !all.isEmpty else { return [] }
        let start = ((destination.currentTripDay - 1) * 3) % all.count
        var slice: [PhraseItem] = []
        for offset in 0..<min(3, all.count) {
            slice.append(all[(start + offset) % all.count])
        }
        return slice
    }

    func openPacking(for destinationId: UUID) -> [TripTask] {
        tripTasks.filter { $0.destinationId == destinationId && !$0.completed }
    }

    func upsertDestination(_ item: Destination, attachKits: Bool = false) {
        let isNew = !destinations.contains { $0.id == item.id }
        if let index = destinations.firstIndex(where: { $0.id == item.id }) {
            destinations[index] = item
        } else {
            destinations.insert(item, at: 0)
        }
        if isNew && attachKits {
            attachCatalogKits(for: item)
        }
        lastViewedDestination = item.id
        activeTripId = item.id
        save()
        TripReminderScheduler.refresh(for: item)
    }

    func deleteDestination(_ id: UUID) {
        if let cover = destinations.first(where: { $0.id == id })?.coverFileName {
            CoverImageStore.delete(cover)
        }
        destinations.removeAll { $0.id == id }
        tripTasks.removeAll { $0.destinationId == id }
        phrases.removeAll { $0.destinationId == id }
        itineraryDays.removeAll { $0.destinationId == id }
        if lastViewedDestination == id { lastViewedDestination = nil }
        if activeTripId == id { activeTripId = nil }
        if selectedLocaleID == id { selectedLocaleID = nil }
        save()
        TripReminderScheduler.cancel(for: id)
    }

    func markVisited(_ id: UUID) {
        guard let index = destinations.firstIndex(where: { $0.id == id }) else { return }
        destinations[index].visited.toggle()
        save()
        TripReminderScheduler.refresh(for: destinations[index])
    }

    func setJournal(for id: UUID, text: String, markVisited: Bool) {
        guard let index = destinations.firstIndex(where: { $0.id == id }) else { return }
        destinations[index].journal = text
        if markVisited {
            destinations[index].visited = true
        }
        save()
        TripReminderScheduler.refresh(for: destinations[index])
    }

    func upsertTask(_ task: TripTask) {
        if let index = tripTasks.firstIndex(where: { $0.id == task.id }) {
            tripTasks[index] = task
        } else {
            tripTasks.append(task)
        }
        activeTripId = task.destinationId
        save()
    }

    func deleteTask(_ id: UUID) {
        tripTasks.removeAll { $0.id == id }
        save()
    }

    func upsertPhrase(_ item: PhraseItem) {
        if let index = phrases.firstIndex(where: { $0.id == item.id }) {
            phrases[index] = item
        } else {
            phrases.append(item)
        }
        selectedLocaleID = item.destinationId
        save()
    }

    func deletePhrase(_ id: UUID) {
        phrases.removeAll { $0.id == id }
        save()
    }

    func upsertStop(_ item: RouteStop) {
        if let index = itineraryDays.firstIndex(where: { $0.id == item.id }) {
            itineraryDays[index] = item
        } else {
            itineraryDays.append(item)
        }
        itineraryDays.sort { $0.stopIndex < $1.stopIndex }
        activeTripId = item.destinationId
        save()
    }

    func deleteStop(_ id: UUID) {
        itineraryDays.removeAll { $0.id == id }
        save()
    }

    func attachCatalogKits(for destination: Destination) {
        if tripTasks.filter({ $0.destinationId == destination.id }).isEmpty {
            tripTasks.append(contentsOf: TripCatalog.packingTasks(for: destination))
        }
        if phrases.filter({ $0.destinationId == destination.id }).isEmpty {
            phrases.append(contentsOf: TripCatalog.phrasePack(
                language: destination.phraseLanguage,
                destinationId: destination.id
            ))
        }
        save()
    }

    func resetAllData() {
        destinations.forEach { CoverImageStore.delete($0.coverFileName) }
        TripReminderScheduler.cancelAll()
        let keys = [destinationsKey, tasksKey, phrasesKey, itineraryKey, lastViewedKey, activeTripKey, localeKey, catalogSeedKey]
        keys.forEach { defaults.removeObject(forKey: $0) }
        destinations = []
        tripTasks = []
        phrases = []
        itineraryDays = []
        lastViewedDestination = nil
        activeTripId = nil
        selectedLocaleID = nil
        seedCatalog()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    private func seedCatalog() {
        let bundle = TripCatalog.sampleBundle()
        destinations = bundle.destinations
        tripTasks = bundle.tasks
        phrases = bundle.phrases
        itineraryDays = bundle.stops
        activeTripId = bundle.destinations.first(where: \.isHappeningNow)?.id ?? bundle.destinations.first?.id
        lastViewedDestination = activeTripId
        defaults.set(true, forKey: catalogSeedKey)
        save()
    }

    private func encode<T: Encodable>(_ value: T, key: String) -> Void {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
