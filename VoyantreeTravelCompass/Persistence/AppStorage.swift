import Foundation
import Combine

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var destinations: [Destination] = []
    @Published var tripTasks: [TripTask] = []
    @Published var phrases: [PhraseItem] = []
    @Published var itineraryDays: [ItineraryDay] = []
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
        itineraryDays = decode([ItineraryDay].self, key: itineraryKey) ?? []
        if let raw = defaults.string(forKey: lastViewedKey) {
            lastViewedDestination = UUID(uuidString: raw)
        }
        if let raw = defaults.string(forKey: activeTripKey) {
            activeTripId = UUID(uuidString: raw)
        }
        if let raw = defaults.string(forKey: localeKey) {
            selectedLocaleID = UUID(uuidString: raw)
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

    func upsertDestination(_ item: Destination) {
        if let index = destinations.firstIndex(where: { $0.id == item.id }) {
            destinations[index] = item
        } else {
            destinations.insert(item, at: 0)
        }
        lastViewedDestination = item.id
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

    func upsertItineraryDay(_ item: ItineraryDay) {
        if let index = itineraryDays.firstIndex(where: { $0.id == item.id }) {
            itineraryDays[index] = item
        } else {
            itineraryDays.append(item)
        }
        itineraryDays.sort { $0.dayIndex < $1.dayIndex }
        save()
    }

    func deleteItineraryDay(_ id: UUID) {
        itineraryDays.removeAll { $0.id == id }
        save()
    }

    func prepareTrip(for destination: Destination) {
        let existing = tripTasks.filter { $0.destinationId == destination.id }
        if existing.isEmpty {
            var seeds: [TripTask] = [
                TripTask(id: UUID(), destinationId: destination.id, title: "Confirm lodging", completed: false, category: TaskCategory.preDeparture.rawValue),
                TripTask(id: UUID(), destinationId: destination.id, title: "Check entry documents", completed: false, category: TaskCategory.preDeparture.rawValue),
                TripTask(id: UUID(), destinationId: destination.id, title: "Local transport plan", completed: false, category: TaskCategory.onArrival.rawValue)
            ]
            seeds.append(contentsOf: ClimateKind.packingTitles(for: destination.climate).map { title in
                TripTask(id: UUID(), destinationId: destination.id, title: title, completed: false, category: TaskCategory.packing.rawValue)
            })
            tripTasks.append(contentsOf: seeds)
        }
        let existingPhrases = phrases.filter { $0.destinationId == destination.id }
        if existingPhrases.isEmpty {
            let seeds = [
                PhraseItem(id: UUID(), destinationId: destination.id, original: "Hello", translation: "Hello", category: PhraseCategory.greeting.rawValue),
                PhraseItem(id: UUID(), destinationId: destination.id, original: "Thank you", translation: "Thank you", category: PhraseCategory.greeting.rawValue),
                PhraseItem(id: UUID(), destinationId: destination.id, original: "Where is the station?", translation: "Where is the station?", category: PhraseCategory.transport.rawValue),
                PhraseItem(id: UUID(), destinationId: destination.id, original: "A table for two, please", translation: "A table for two, please", category: PhraseCategory.food.rawValue),
                PhraseItem(id: UUID(), destinationId: destination.id, original: "I need help", translation: "I need help", category: PhraseCategory.emergency.rawValue)
            ]
            phrases.append(contentsOf: seeds)
        }
        activeTripId = destination.id
        selectedLocaleID = destination.id
        save()
    }

    func resetAllData() {
        destinations.forEach { CoverImageStore.delete($0.coverFileName) }
        TripReminderScheduler.cancelAll()
        let keys = [destinationsKey, tasksKey, phrasesKey, itineraryKey, lastViewedKey, activeTripKey, localeKey]
        keys.forEach { defaults.removeObject(forKey: $0) }
        destinations = []
        tripTasks = []
        phrases = []
        itineraryDays = []
        lastViewedDestination = nil
        activeTripId = nil
        selectedLocaleID = nil
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
