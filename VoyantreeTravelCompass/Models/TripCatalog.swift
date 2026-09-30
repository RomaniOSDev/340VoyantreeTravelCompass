import Foundation

enum TripCatalog {
    static func attachKits(to destination: Destination) -> (tasks: [TripTask], phrases: [PhraseItem]) {
        let tasks = packingTasks(for: destination)
        let phrases = phrasePack(language: destination.phraseLanguage, destinationId: destination.id)
        return (tasks, phrases)
    }

    static func packingTasks(for destination: Destination) -> [TripTask] {
        var items: [TripTask] = [
            TripTask(
                id: UUID(),
                destinationId: destination.id,
                title: "Confirm lodging check-in window",
                completed: false,
                category: TaskCategory.preDeparture.rawValue
            ),
            TripTask(
                id: UUID(),
                destinationId: destination.id,
                title: "Download offline maps for walking days",
                completed: false,
                category: TaskCategory.preDeparture.rawValue
            ),
            TripTask(
                id: UUID(),
                destinationId: destination.id,
                title: "First-stop walking line from arrival",
                completed: false,
                category: TaskCategory.onArrival.rawValue
            )
        ]
        items.append(contentsOf: destination.scenario.packingTitles.map { title in
            TripTask(
                id: UUID(),
                destinationId: destination.id,
                title: title,
                completed: false,
                category: TaskCategory.packing.rawValue
            )
        })
        return items
    }

    static func phrasePack(language: String, destinationId: UUID) -> [PhraseItem] {
        templates(for: language).map { row in
            PhraseItem(
                id: UUID(),
                destinationId: destinationId,
                original: row.original,
                translation: row.english,
                category: row.category,
                transliteration: row.transliteration,
                language: language
            )
        }
    }

    static func sampleBundle() -> (
        destinations: [Destination],
        tasks: [TripTask],
        phrases: [PhraseItem],
        stops: [RouteStop]
    ) {
        let trips = sampleTrips()
        return (
            trips.map(\.destination),
            trips.flatMap(\.tasks),
            trips.flatMap(\.phrases),
            trips.flatMap(\.stops)
        )
    }

    private struct PackedTrip {
        let destination: Destination
        let tasks: [TripTask]
        let phrases: [PhraseItem]
        let stops: [RouteStop]
    }

    private static func sampleTrips() -> [PackedTrip] {
        [
            packed(
                id: UUID(uuidString: "A1B0C3D4-E5F6-4718-9201-AABBCCDDEE01")!,
                name: "Right Bank Walk",
                country: "France",
                startOffset: -1,
                length: 4,
                notes: "Keep the Seine on your right from Notre-Dame to the tower.",
                timezone: "Europe/Paris",
                scenario: .cityWeekend,
                language: PhraseLanguage.french.rawValue,
                pins: [
                    ("Notre-Dame parvis", "Start on the square, face the towers.", 48.8530, 2.3499),
                    ("Cour Carrée, Louvre", "Cut through the courtyard, not the pyramid queue.", 48.8606, 2.3376),
                    ("Pont des Arts", "Cross for the Left Bank view.", 48.8583, 2.3375),
                    ("Trocadéro terrace", "Final bearing on the tower axis.", 48.8616, 2.2893)
                ]
            ),
            packed(
                id: UUID(uuidString: "A1B0C3D4-E5F6-4718-9201-AABBCCDDEE02")!,
                name: "Higashiyama Line",
                country: "Japan",
                startOffset: 12,
                length: 4,
                notes: "Walk downhill from Kiyomizu toward Gion before dusk.",
                timezone: "Asia/Tokyo",
                scenario: .cityWeekend,
                language: PhraseLanguage.japanese.rawValue,
                pins: [
                    ("Fushimi Inari gate", "Count torii until the first ridge view.", 34.9671, 135.7727),
                    ("Kiyomizu-dera terrace", "Wooden stage above the maple slope.", 34.9949, 135.7850),
                    ("Ninenzaka", "Stone lane toward Yasaka.", 34.9984, 135.7806),
                    ("Gion Shirakawa", "Lanterns along the canal.", 35.0036, 135.7780)
                ]
            ),
            packed(
                id: UUID(uuidString: "A1B0C3D4-E5F6-4718-9201-AABBCCDDEE03")!,
                name: "Eixample to Sea",
                country: "Spain",
                startOffset: 24,
                length: 3,
                notes: "Grid streets, then drop to the beach for sunset.",
                timezone: "Europe/Madrid",
                scenario: .cityWeekend,
                language: PhraseLanguage.spanish.rawValue,
                pins: [
                    ("Sagrada Família nativity", "Stand on Carrer de la Marina.", 41.4036, 2.1744),
                    ("Hospital de Sant Pau", "Quiet gardens north of the basilica.", 41.4136, 2.1744),
                    ("Palau de la Música", "Old city edge after the grid.", 41.3876, 2.1752),
                    ("Barceloneta breakwater", "Walk the arm for open water.", 41.3769, 2.1925)
                ]
            ),
            packed(
                id: UUID(uuidString: "A1B0C3D4-E5F6-4718-9201-AABBCCDDEE04")!,
                name: "Forum Spine",
                country: "Italy",
                startOffset: 38,
                length: 4,
                notes: "Keep the Forum on your left from Colosseo to the river.",
                timezone: "Europe/Rome",
                scenario: .cityWeekend,
                language: PhraseLanguage.italian.rawValue,
                pins: [
                    ("Colosseo SE gate", "Start outside, not in the ticket maze.", 41.8902, 12.4922),
                    ("Foro Romano overlook", "Via dei Fori Imperiali sidewalk.", 41.8925, 12.4853),
                    ("Pantheon porch", "Bear northwest through alleys.", 41.8986, 12.4769),
                    ("Ponte Sisto", "Cross into Trastevere light.", 41.8924, 12.4708)
                ]
            ),
            packed(
                id: UUID(uuidString: "A1B0C3D4-E5F6-4718-9201-AABBCCDDEE05")!,
                name: "Chamonix Ridges",
                country: "France",
                startOffset: 52,
                length: 3,
                notes: "Winter traction on packed snow. Turn around if cloud drops.",
                timezone: "Europe/Paris",
                scenario: .winterHike,
                language: PhraseLanguage.french.rawValue,
                pins: [
                    ("Aiguille du Midi base", "Cable check before the first lift.", 45.9237, 6.8694),
                    ("Signal Forbes", "Short balcony above town.", 45.9345, 6.8702),
                    ("Lac Blanc trailhead", "Last trees before the hanging lake.", 45.9817, 6.8874),
                    ("Flégère terrace", "Exit bearing back to the valley.", 45.9606, 6.8879)
                ]
            ),
            packed(
                id: UUID(uuidString: "A1B0C3D4-E5F6-4718-9201-AABBCCDDEE06")!,
                name: "Naha Shore Loop",
                country: "Japan",
                startOffset: 68,
                length: 5,
                notes: "Shade between beach stops. Reef shoes on the limestone.",
                timezone: "Asia/Tokyo",
                scenario: .beach,
                language: PhraseLanguage.japanese.rawValue,
                pins: [
                    ("Kokusai-dori gate", "Arrival street food before the coast.", 26.2173, 127.6889),
                    ("Shurijo park", "Castle ridge, then drop west.", 26.2170, 127.7195),
                    ("Naminoue beach", "First swim shelf in town.", 26.2206, 127.6719),
                    ("Sunset beach, North", "Longer sand north of the city.", 26.3165, 127.7556)
                ]
            )
        ]
    }

    private static func packed(
        id: UUID,
        name: String,
        country: String,
        startOffset: Int,
        length: Int,
        notes: String,
        timezone: String,
        scenario: TripScenario,
        language: String,
        pins: [(String, String, Double, Double)]
    ) -> PackedTrip {
        let range = dateRange(offset: startOffset, length: length)
        let destination = Destination(
            id: id,
            name: name,
            country: country,
            date: range.start,
            endDate: range.end,
            notes: notes,
            visited: false,
            timezone: timezone,
            climate: scenario.rawValue,
            journal: "",
            coverFileName: nil,
            phraseLanguage: language
        )
        let stops = pins.enumerated().map { index, pin in
            RouteStop(
                id: UUID(),
                destinationId: id,
                stopIndex: index + 1,
                title: pin.0,
                notes: pin.1,
                latitude: pin.2,
                longitude: pin.3
            )
        }
        return PackedTrip(
            destination: destination,
            tasks: packingTasks(for: destination),
            phrases: phrasePack(language: language, destinationId: id),
            stops: stops
        )
    }

    private static func dateRange(offset: Int, length: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: offset, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: max(0, length - 1), to: start) ?? start
        return (start, end)
    }

    private struct PhraseTemplate {
        let original: String
        let transliteration: String
        let english: String
        let category: String
    }

    private static func templates(for language: String) -> [PhraseTemplate] {
        switch PhraseLanguage(rawValue: language) ?? .french {
        case .japanese: return japanese
        case .french: return french
        case .spanish: return spanish
        case .italian: return italian
        }
    }

    private static let greeting = PhraseCategory.greeting.rawValue
    private static let transport = PhraseCategory.transport.rawValue
    private static let food = PhraseCategory.food.rawValue
    private static let emergency = PhraseCategory.emergency.rawValue

    private static let japanese: [PhraseTemplate] = [
        .init(original: "こんにちは", transliteration: "Konnichiwa", english: "Hello", category: greeting),
        .init(original: "ありがとうございます", transliteration: "Arigatō gozaimasu", english: "Thank you", category: greeting),
        .init(original: "すみません", transliteration: "Sumimasen", english: "Excuse me", category: greeting),
        .init(original: "英語を話せますか？", transliteration: "Eigo o hanasemasu ka?", english: "Do you speak English?", category: greeting),
        .init(original: "駅はどこですか？", transliteration: "Eki wa doko desu ka?", english: "Where is the station?", category: transport),
        .init(original: "この電車は行きますか？", transliteration: "Kono densha wa ikimasu ka?", english: "Does this train go there?", category: transport),
        .init(original: "切符を二枚ください", transliteration: "Kippu o nimai kudasai", english: "Two tickets, please", category: transport),
        .init(original: "左に曲がってください", transliteration: "Hidari ni magatte kudasai", english: "Please turn left", category: transport),
        .init(original: "道に迷いました", transliteration: "Michi ni mayoimashita", english: "I am lost", category: transport),
        .init(original: "メニューをください", transliteration: "Menyū o kudasai", english: "The menu, please", category: food),
        .init(original: "水をください", transliteration: "Mizu o kudasai", english: "Water, please", category: food),
        .init(original: "おいしいです", transliteration: "Oishii desu", english: "This is delicious", category: food),
        .init(original: "お会計をお願いします", transliteration: "Okaikei o onegai shimasu", english: "The bill, please", category: food),
        .init(original: "予約しています", transliteration: "Yoyaku shite imasu", english: "I have a reservation", category: food),
        .init(original: "いくらですか？", transliteration: "Ikura desu ka?", english: "How much is this?", category: food),
        .init(original: "助けてください", transliteration: "Tasukete kudasai", english: "Please help me", category: emergency),
        .init(original: "病院はどこですか？", transliteration: "Byōin wa doko desu ka?", english: "Where is the hospital?", category: emergency),
        .init(original: "トイレはどこですか？", transliteration: "Toire wa doko desu ka?", english: "Where is the restroom?", category: emergency)
    ]

    private static let french: [PhraseTemplate] = [
        .init(original: "Bonjour", transliteration: "bon-ZHOOR", english: "Hello", category: greeting),
        .init(original: "Merci beaucoup", transliteration: "mair-SEE bo-KOO", english: "Thank you very much", category: greeting),
        .init(original: "Excusez-moi", transliteration: "ex-kew-ZAY mwah", english: "Excuse me", category: greeting),
        .init(original: "Parlez-vous anglais ?", transliteration: "par-LAY voo ahn-GLEH", english: "Do you speak English?", category: greeting),
        .init(original: "Où est la gare ?", transliteration: "oo eh la GAR", english: "Where is the station?", category: transport),
        .init(original: "Un billet pour…, s’il vous plaît", transliteration: "uh bee-YEH poor", english: "A ticket to…, please", category: transport),
        .init(original: "Je suis perdu", transliteration: "zhuh swee pair-DEW", english: "I am lost", category: transport),
        .init(original: "À gauche, s’il vous plaît", transliteration: "ah GOSH", english: "To the left, please", category: transport),
        .init(original: "C’est dans quelle direction ?", transliteration: "seh dahn kel dee-rek-SYON", english: "Which way is that?", category: transport),
        .init(original: "Une table pour deux", transliteration: "ewn TAH-bluh poor duh", english: "A table for two", category: food),
        .init(original: "De l’eau, s’il vous plaît", transliteration: "duh LO", english: "Water, please", category: food),
        .init(original: "L’addition, s’il vous plaît", transliteration: "lad-ee-SYON", english: "The bill, please", category: food),
        .init(original: "C’est délicieux", transliteration: "seh day-lee-SYUH", english: "This is delicious", category: food),
        .init(original: "J’ai une réservation", transliteration: "zhay ewn ray-zair-va-SYON", english: "I have a reservation", category: food),
        .init(original: "Combien ça coûte ?", transliteration: "kom-BYEN sa koot", english: "How much is this?", category: food),
        .init(original: "J’ai besoin d’aide", transliteration: "zhay buh-ZWAN ded", english: "I need help", category: emergency),
        .init(original: "Où est l’hôpital ?", transliteration: "oo eh lo-pee-TAL", english: "Where is the hospital?", category: emergency),
        .init(original: "Où sont les toilettes ?", transliteration: "oo son lay twah-LET", english: "Where is the restroom?", category: emergency)
    ]

    private static let spanish: [PhraseTemplate] = [
        .init(original: "Hola", transliteration: "OH-lah", english: "Hello", category: greeting),
        .init(original: "Gracias", transliteration: "GRAH-syahs", english: "Thank you", category: greeting),
        .init(original: "Perdón", transliteration: "pair-DOHN", english: "Excuse me", category: greeting),
        .init(original: "¿Habla inglés?", transliteration: "AH-blah in-GLEHS", english: "Do you speak English?", category: greeting),
        .init(original: "¿Dónde está la estación?", transliteration: "DOHN-deh es-TAH la es-tah-SYOHN", english: "Where is the station?", category: transport),
        .init(original: "Un billete a…, por favor", transliteration: "oon bee-YEH-teh ah", english: "A ticket to…, please", category: transport),
        .init(original: "Estoy perdido", transliteration: "es-TOY pair-DEE-doh", english: "I am lost", category: transport),
        .init(original: "A la izquierda", transliteration: "ah lah eeth-KYAIR-dah", english: "To the left", category: transport),
        .init(original: "¿Por aquí se va a…?", transliteration: "por ah-KEE seh vah ah", english: "Is this the way to…?", category: transport),
        .init(original: "Una mesa para dos", transliteration: "OO-nah MEH-sah PAH-rah dos", english: "A table for two", category: food),
        .init(original: "Agua, por favor", transliteration: "AH-gwah", english: "Water, please", category: food),
        .init(original: "La cuenta, por favor", transliteration: "la KWEN-tah", english: "The bill, please", category: food),
        .init(original: "Está delicioso", transliteration: "es-TAH deh-lee-SYOH-so", english: "This is delicious", category: food),
        .init(original: "Tengo una reserva", transliteration: "TEN-go OO-nah reh-SEHR-bah", english: "I have a reservation", category: food),
        .init(original: "¿Cuánto cuesta?", transliteration: "KWAHN-toh KWES-tah", english: "How much is this?", category: food),
        .init(original: "Necesito ayuda", transliteration: "neh-seh-SEE-toh ah-YOO-dah", english: "I need help", category: emergency),
        .init(original: "¿Dónde está el hospital?", transliteration: "DOHN-deh es-TAH el os-pee-TAHL", english: "Where is the hospital?", category: emergency),
        .init(original: "¿Dónde está el baño?", transliteration: "DOHN-deh es-TAH el BAH-nyo", english: "Where is the restroom?", category: emergency)
    ]

    private static let italian: [PhraseTemplate] = [
        .init(original: "Ciao", transliteration: "CHOW", english: "Hello", category: greeting),
        .init(original: "Grazie mille", transliteration: "GRAH-tsyeh MEEL-leh", english: "Thank you very much", category: greeting),
        .init(original: "Scusi", transliteration: "SKOO-zee", english: "Excuse me", category: greeting),
        .init(original: "Parla inglese?", transliteration: "PAR-lah in-GLEH-zeh", english: "Do you speak English?", category: greeting),
        .init(original: "Dov’è la stazione?", transliteration: "doh-VEH lah sta-TSYOH-neh", english: "Where is the station?", category: transport),
        .init(original: "Un biglietto per…, per favore", transliteration: "oon beel-YET-toh pair", english: "A ticket to…, please", category: transport),
        .init(original: "Mi sono perso", transliteration: "mee SO-no PAIR-so", english: "I am lost", category: transport),
        .init(original: "A sinistra, per favore", transliteration: "ah see-NEE-strah", english: "To the left, please", category: transport),
        .init(original: "È questa la strada per…?", transliteration: "eh KWES-tah lah STRAH-dah pair", english: "Is this the road to…?", category: transport),
        .init(original: "Un tavolo per due", transliteration: "oon TAH-vo-lo pair DOO-eh", english: "A table for two", category: food),
        .init(original: "Dell’acqua, per favore", transliteration: "dell AH-kwah", english: "Water, please", category: food),
        .init(original: "Il conto, per favore", transliteration: "eel KON-toh", english: "The bill, please", category: food),
        .init(original: "È delizioso", transliteration: "eh deh-lee-TSYOH-zo", english: "This is delicious", category: food),
        .init(original: "Ho una prenotazione", transliteration: "oh OO-nah preh-no-tah-TSYOH-neh", english: "I have a reservation", category: food),
        .init(original: "Quanto costa?", transliteration: "KWAHN-toh KO-stah", english: "How much is this?", category: food),
        .init(original: "Ho bisogno di aiuto", transliteration: "oh bee-ZOH-nyo dee ah-YOO-toh", english: "I need help", category: emergency),
        .init(original: "Dov’è l’ospedale?", transliteration: "doh-VEH los-peh-DAH-leh", english: "Where is the hospital?", category: emergency),
        .init(original: "Dov’è il bagno?", transliteration: "doh-VEH eel BAH-nyo", english: "Where is the restroom?", category: emergency)
    ]
}
