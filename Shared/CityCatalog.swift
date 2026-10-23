import Foundation

enum CityCatalog {
    // Default cities — match the design studies.
    static let lisbon = CityEntity(id: "lisbon", name: "Lisbon", timeZoneIdentifier: "Europe/Lisbon")
    static let newYork = CityEntity(id: "new-york", name: "New York", timeZoneIdentifier: "America/New_York")
    static let tokyo = CityEntity(id: "tokyo", name: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
    static let sydney = CityEntity(id: "sydney", name: "Sydney", timeZoneIdentifier: "Australia/Sydney")

    static let london = CityEntity(id: "london", name: "London", timeZoneIdentifier: "Europe/London")
    static let paris = CityEntity(id: "paris", name: "Paris", timeZoneIdentifier: "Europe/Paris")
    static let berlin = CityEntity(id: "berlin", name: "Berlin", timeZoneIdentifier: "Europe/Berlin")
    static let madrid = CityEntity(id: "madrid", name: "Madrid", timeZoneIdentifier: "Europe/Madrid")
    static let rome = CityEntity(id: "rome", name: "Rome", timeZoneIdentifier: "Europe/Rome")
    static let amsterdam = CityEntity(id: "amsterdam", name: "Amsterdam", timeZoneIdentifier: "Europe/Amsterdam")
    static let stockholm = CityEntity(id: "stockholm", name: "Stockholm", timeZoneIdentifier: "Europe/Stockholm")
    static let zurich = CityEntity(id: "zurich", name: "Zürich", timeZoneIdentifier: "Europe/Zurich")
    static let reykjavik = CityEntity(id: "reykjavik", name: "Reykjavík", timeZoneIdentifier: "Atlantic/Reykjavik")
    static let istanbul = CityEntity(id: "istanbul", name: "Istanbul", timeZoneIdentifier: "Europe/Istanbul")
    static let moscow = CityEntity(id: "moscow", name: "Moscow", timeZoneIdentifier: "Europe/Moscow")

    static let sanFrancisco = CityEntity(id: "san-francisco", name: "San Francisco", timeZoneIdentifier: "America/Los_Angeles")
    static let losAngeles = CityEntity(id: "los-angeles", name: "Los Angeles", timeZoneIdentifier: "America/Los_Angeles")
    static let chicago = CityEntity(id: "chicago", name: "Chicago", timeZoneIdentifier: "America/Chicago")
    static let denver = CityEntity(id: "denver", name: "Denver", timeZoneIdentifier: "America/Denver")
    static let miami = CityEntity(id: "miami", name: "Miami", timeZoneIdentifier: "America/New_York")
    static let toronto = CityEntity(id: "toronto", name: "Toronto", timeZoneIdentifier: "America/Toronto")
    static let mexicoCity = CityEntity(id: "mexico-city", name: "Mexico City", timeZoneIdentifier: "America/Mexico_City")
    static let saoPaulo = CityEntity(id: "sao-paulo", name: "São Paulo", timeZoneIdentifier: "America/Sao_Paulo")
    static let rio = CityEntity(id: "rio", name: "Rio de Janeiro", timeZoneIdentifier: "America/Sao_Paulo")
    static let buenosAires = CityEntity(id: "buenos-aires", name: "Buenos Aires", timeZoneIdentifier: "America/Argentina/Buenos_Aires")
    static let honolulu = CityEntity(id: "honolulu", name: "Honolulu", timeZoneIdentifier: "Pacific/Honolulu")
    static let vancouver = CityEntity(id: "vancouver", name: "Vancouver", timeZoneIdentifier: "America/Vancouver")
    static let bogota = CityEntity(id: "bogota", name: "Bogotá", timeZoneIdentifier: "America/Bogota")
    static let lima = CityEntity(id: "lima", name: "Lima", timeZoneIdentifier: "America/Lima")
    static let santiago = CityEntity(id: "santiago", name: "Santiago", timeZoneIdentifier: "America/Santiago")

    static let dubai = CityEntity(id: "dubai", name: "Dubai", timeZoneIdentifier: "Asia/Dubai")
    static let mumbai = CityEntity(id: "mumbai", name: "Mumbai", timeZoneIdentifier: "Asia/Kolkata")
    static let delhi = CityEntity(id: "delhi", name: "Delhi", timeZoneIdentifier: "Asia/Kolkata")
    static let bangkok = CityEntity(id: "bangkok", name: "Bangkok", timeZoneIdentifier: "Asia/Bangkok")
    static let singapore = CityEntity(id: "singapore", name: "Singapore", timeZoneIdentifier: "Asia/Singapore")
    static let hongKong = CityEntity(id: "hong-kong", name: "Hong Kong", timeZoneIdentifier: "Asia/Hong_Kong")
    static let seoul = CityEntity(id: "seoul", name: "Seoul", timeZoneIdentifier: "Asia/Seoul")
    static let shanghai = CityEntity(id: "shanghai", name: "Shanghai", timeZoneIdentifier: "Asia/Shanghai")
    static let manila = CityEntity(id: "manila", name: "Manila", timeZoneIdentifier: "Asia/Manila")
    static let jakarta = CityEntity(id: "jakarta", name: "Jakarta", timeZoneIdentifier: "Asia/Jakarta")
    static let auckland = CityEntity(id: "auckland", name: "Auckland", timeZoneIdentifier: "Pacific/Auckland")

    static let cairo = CityEntity(id: "cairo", name: "Cairo", timeZoneIdentifier: "Africa/Cairo")
    static let lagos = CityEntity(id: "lagos", name: "Lagos", timeZoneIdentifier: "Africa/Lagos")
    static let nairobi = CityEntity(id: "nairobi", name: "Nairobi", timeZoneIdentifier: "Africa/Nairobi")
    static let capeTown = CityEntity(id: "cape-town", name: "Cape Town", timeZoneIdentifier: "Africa/Johannesburg")

    /// Defaults per widget family and style, so a freshly placed widget already looks composed.
    static let focusDefaults = [lisbon]
    static let duoDefaults = [lisbon, tokyo]
    static let listDefaults = [sanFrancisco, london, tokyo]
    static let trioDefaults = [newYork, tokyo, sydney]
    static let gridDefaults = [sanFrancisco, london, dubai, tokyo]

    /// Backfill order once a layout's own defaults are used up.
    static let defaults = [lisbon, newYork, tokyo, sydney]

    static let all: [CityEntity] = [
        lisbon, london, paris, berlin, madrid, rome, amsterdam, stockholm, zurich,
        reykjavik, istanbul, moscow,
        newYork, sanFrancisco, losAngeles, chicago, denver, miami, toronto, vancouver,
        mexicoCity, bogota, lima, santiago, saoPaulo, rio, buenosAires, honolulu,
        dubai, mumbai, delhi, bangkok, singapore, hongKong, shanghai, manila, jakarta,
        seoul, tokyo, sydney, auckland,
        cairo, lagos, nairobi, capeTown
    ].sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

    static func city(id: String) -> CityEntity? {
        all.first { $0.id == id }
    }

    /// Resolves a city saved by Edit Widget. Settings store the city's name so the picker
    /// always shows something readable; earlier builds stored the ID, so both match.
    static func city(setting: String) -> CityEntity? {
        all.first { $0.name == setting } ?? city(id: setting)
    }

    /// The catalog grouped for Edit Widget's picker, regions in alphabetical order.
    static var regions: [(name: String, cities: [CityEntity])] {
        Dictionary(grouping: all, by: \.region)
            .sorted { $0.key < $1.key }
            .map { (name: $0.key, cities: $0.value) }
    }

    /// Resolves `limit` distinct cities from optional per-slot configuration and fallbacks,
    /// backfilling any empty or duplicate slots so a multi-city widget never loses a column/cell.
    static func resolvedCities(
        configured: [CityEntity?],
        fallbacks: [CityEntity],
        limit: Int
    ) -> [CityEntity] {
        guard limit > 0 else { return [] }

        let backfills = fallbacks + defaults + all
        var result: [CityEntity] = []
        var seen = Set<String>()

        for index in 0..<limit {
            if index < configured.count,
               let chosen = configured[index],
               seen.insert(chosen.id).inserted {
                result.append(chosen)
                continue
            }

            // Avoid stealing a city that the user explicitly placed in a later slot.
            let reservedLater = Set(
                configured
                    .dropFirst(index + 1)
                    .prefix(max(0, limit - index - 1))
                    .compactMap { $0?.id }
            )

            let slotCandidates: [CityEntity]
            if index < fallbacks.count {
                slotCandidates = [fallbacks[index]] + backfills
            } else {
                slotCandidates = backfills
            }

            if let backfill = slotCandidates.first(where: {
                !seen.contains($0.id) && !reservedLater.contains($0.id)
            }) ?? slotCandidates.first(where: { !seen.contains($0.id) }) {
                seen.insert(backfill.id)
                result.append(backfill)
            }
        }

        return result
    }
}
