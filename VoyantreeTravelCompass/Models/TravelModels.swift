import Foundation

struct Destination: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var country: String
    var date: Date
    var endDate: Date
    var notes: String
    var visited: Bool
    var timezone: String
    var climate: String
    var journal: String
    var coverFileName: String?
    var phraseLanguage: String

    enum CodingKeys: String, CodingKey {
        case id, name, country, date, endDate, notes, visited, timezone, climate, journal, coverFileName, phraseLanguage
    }

    init(
        id: UUID,
        name: String,
        country: String,
        date: Date,
        endDate: Date,
        notes: String,
        visited: Bool,
        timezone: String,
        climate: String,
        journal: String = "",
        coverFileName: String? = nil,
        phraseLanguage: String = PhraseLanguage.french.rawValue
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.date = date
        self.endDate = endDate
        self.notes = notes
        self.visited = visited
        self.timezone = timezone
        self.climate = climate
        self.journal = journal
        self.coverFileName = coverFileName
        self.phraseLanguage = phraseLanguage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        country = try container.decode(String.self, forKey: .country)
        date = try container.decode(Date.self, forKey: .date)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate) ?? date
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        visited = try container.decodeIfPresent(Bool.self, forKey: .visited) ?? false
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone) ?? "Local"
        let rawClimate = try container.decodeIfPresent(String.self, forKey: .climate) ?? TripScenario.cityWeekend.rawValue
        climate = TripScenario.migrated(from: rawClimate).rawValue
        journal = try container.decodeIfPresent(String.self, forKey: .journal) ?? ""
        coverFileName = try container.decodeIfPresent(String.self, forKey: .coverFileName)
        phraseLanguage = try container.decodeIfPresent(String.self, forKey: .phraseLanguage) ?? PhraseLanguage.french.rawValue
    }

    var scenario: TripScenario {
        TripScenario.migrated(from: climate)
    }

    var durationDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: endDate)
        let span = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, span + 1)
    }

    var dateRangeText: String {
        let start = date.formatted(date: .abbreviated, time: .omitted)
        if Calendar.current.isDate(date, inSameDayAs: endDate) {
            return start
        }
        return "\(start) – \(endDate.formatted(date: .abbreviated, time: .omitted))"
    }

    var daysUntilStart: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
    }

    var isHappeningNow: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: endDate)
        return today >= start && today <= end
    }

    var currentTripDay: Int {
        guard isHappeningNow else { return 1 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        return (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1
    }

    var countdownText: String {
        if isHappeningNow { return "Happening now · day \(currentTripDay)" }
        switch daysUntilStart {
        case 0: return "Starts today"
        case 1: return "Tomorrow"
        case let days where days > 1: return "In \(days) days"
        case let days: return "Started \(abs(days)) days ago"
        }
    }
}

struct TripTask: Codable, Identifiable, Hashable {
    var id: UUID
    var destinationId: UUID
    var title: String
    var completed: Bool
    var category: String
}

struct PhraseItem: Codable, Identifiable, Hashable {
    var id: UUID
    var destinationId: UUID
    var original: String
    var translation: String
    var category: String
    var transliteration: String
    var language: String

    enum CodingKeys: String, CodingKey {
        case id, destinationId, original, translation, category, transliteration, language
    }

    init(
        id: UUID,
        destinationId: UUID,
        original: String,
        translation: String,
        category: String = PhraseCategory.greeting.rawValue,
        transliteration: String = "",
        language: String = PhraseLanguage.french.rawValue
    ) {
        self.id = id
        self.destinationId = destinationId
        self.original = original
        self.translation = translation
        self.category = category
        self.transliteration = transliteration
        self.language = language
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        destinationId = try container.decode(UUID.self, forKey: .destinationId)
        original = try container.decode(String.self, forKey: .original)
        translation = try container.decode(String.self, forKey: .translation)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? PhraseCategory.greeting.rawValue
        transliteration = try container.decodeIfPresent(String.self, forKey: .transliteration) ?? ""
        language = try container.decodeIfPresent(String.self, forKey: .language) ?? PhraseLanguage.french.rawValue
    }
}

struct RouteStop: Codable, Identifiable, Hashable {
    var id: UUID
    var destinationId: UUID
    var stopIndex: Int
    var title: String
    var notes: String
    var latitude: Double
    var longitude: Double

    enum CodingKeys: String, CodingKey {
        case id, destinationId, stopIndex, dayIndex, title, notes, latitude, longitude
    }

    init(
        id: UUID,
        destinationId: UUID,
        stopIndex: Int,
        title: String,
        notes: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.destinationId = destinationId
        self.stopIndex = stopIndex
        self.title = title
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        destinationId = try container.decode(UUID.self, forKey: .destinationId)
        stopIndex = try container.decodeIfPresent(Int.self, forKey: .stopIndex)
            ?? container.decodeIfPresent(Int.self, forKey: .dayIndex)
            ?? 1
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(destinationId, forKey: .destinationId)
        try container.encode(stopIndex, forKey: .stopIndex)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    var isPinned: Bool {
        abs(latitude) > 0.0001 || abs(longitude) > 0.0001
    }
}

enum TaskCategory: String, CaseIterable {
    case preDeparture = "Pre-Departure"
    case onArrival = "On Arrival"
    case packing = "Packing"
}

enum PhraseCategory: String, CaseIterable, Identifiable {
    case greeting = "Greeting"
    case transport = "Transport"
    case food = "Food"
    case emergency = "Emergency"

    var id: String { rawValue }
}

enum PhraseLanguage: String, CaseIterable, Identifiable {
    case japanese = "JA"
    case french = "FR"
    case spanish = "ES"
    case italian = "IT"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .japanese: return "Japanese"
        case .french: return "French"
        case .spanish: return "Spanish"
        case .italian: return "Italian"
        }
    }
}

enum TripScenario: String, CaseIterable, Identifiable {
    case cityWeekend = "City weekend"
    case winterHike = "Winter hike"
    case beach = "Beach"
    case longHaulFlight = "Long-haul flight"

    var id: String { rawValue }

    static func migrated(from raw: String) -> TripScenario {
        if let match = TripScenario(rawValue: raw) { return match }
        let key = raw.lowercased()
        if key.contains("tropic") || key.contains("hot") || key.contains("beach") {
            return .beach
        }
        if key.contains("cold") || key.contains("winter") || key.contains("alpine") || key.contains("hike") {
            return .winterHike
        }
        if key.contains("flight") || key.contains("long") {
            return .longHaulFlight
        }
        return .cityWeekend
    }

    var packingTitles: [String] {
        switch self {
        case .cityWeekend:
            return [
                "Compact daypack",
                "Broken-in walking shoes",
                "Light rain shell",
                "Transit card or tickets",
                "Phone battery pack",
                "Evening layer",
                "Offline city map",
                "Small locker lock"
            ]
        case .winterHike:
            return [
                "Insulated shell and puffy",
                "Warm merino base layers",
                "Waterproof boots",
                "Microspikes or traction",
                "Gloves and beanie",
                "Headlamp with spare cell",
                "Hot-drink flask",
                "Emergency bivy or blanket"
            ]
        case .beach:
            return [
                "Reef-safe sunscreen",
                "Quick-dry towel",
                "Swimwear and cover-up",
                "Water shoes",
                "Insect repellent",
                "Dry bag for phone",
                "Reusable water bottle",
                "After-sun lotion"
            ]
        case .longHaulFlight:
            return [
                "Compression socks",
                "Neck pillow",
                "Empty bottle for airside fill",
                "Eye mask and earplugs",
                "Cables plus plug adapter",
                "Cabin snacks and electrolytes",
                "Warm cabin layer",
                "Medication in carry-on",
                "Documents in one pouch"
            ]
        }
    }
}

enum WishlistFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case upcoming = "Upcoming"
    case visited = "Visited"

    var id: String { rawValue }
}

enum WishlistSort: String, CaseIterable, Identifiable {
    case date = "Date"
    case name = "Name"
    case country = "Country"

    var id: String { rawValue }
}
