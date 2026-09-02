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

    enum CodingKeys: String, CodingKey {
        case id, name, country, date, endDate, notes, visited, timezone, climate, journal, coverFileName
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
        coverFileName: String? = nil
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
        climate = try container.decodeIfPresent(String.self, forKey: .climate) ?? ClimateKind.temperate.rawValue
        journal = try container.decodeIfPresent(String.self, forKey: .journal) ?? ""
        coverFileName = try container.decodeIfPresent(String.self, forKey: .coverFileName)
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

    var countdownText: String {
        if isHappeningNow { return "Happening now" }
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

    enum CodingKeys: String, CodingKey {
        case id, destinationId, original, translation, category
    }

    init(id: UUID, destinationId: UUID, original: String, translation: String, category: String = PhraseCategory.greeting.rawValue) {
        self.id = id
        self.destinationId = destinationId
        self.original = original
        self.translation = translation
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        destinationId = try container.decode(UUID.self, forKey: .destinationId)
        original = try container.decode(String.self, forKey: .original)
        translation = try container.decode(String.self, forKey: .translation)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? PhraseCategory.greeting.rawValue
    }
}

struct ItineraryDay: Codable, Identifiable, Hashable {
    var id: UUID
    var destinationId: UUID
    var dayIndex: Int
    var title: String
    var notes: String
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

enum ClimateKind: String, CaseIterable, Identifiable {
    case temperate = "Temperate"
    case tropical = "Tropical"
    case cold = "Cold"

    var id: String { rawValue }

    static func packingTitles(for climate: String) -> [String] {
        let key = climate.lowercased()
        if key.contains("tropic") || key.contains("hot") || key.contains("humid") {
            return [
                "Light breathable layers",
                "Sun protection and hat",
                "Insect repellent",
                "Reusable water bottle"
            ]
        }
        if key.contains("cold") || key.contains("winter") || key.contains("alpine") {
            return [
                "Insulated coat",
                "Warm base layers",
                "Waterproof boots",
                "Gloves and beanie"
            ]
        }
        return [
            "Weather layers",
            "Comfortable walking shoes",
            "Light rain jacket",
            "Daypack"
        ]
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
