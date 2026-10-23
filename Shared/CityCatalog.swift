import Foundation

enum CityCatalog {
    // Default roster — matches the design studies.
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

    static let dubai = CityEntity(id: "dubai", name: "Dubai", timeZoneIdentifier: "Asia/Dubai")
    static let mumbai = CityEntity(id: "mumbai", name: "Mumbai", timeZoneIdentifier: "Asia/Kolkata")
    static let delhi = CityEntity(id: "delhi", name: "Delhi", timeZoneIdentifier: "Asia/Kolkata")
    static let bangkok = CityEntity(id: "bangkok", name: "Bangkok", timeZoneIdentifier: "Asia/Bangkok")
    static let singapore = CityEntity(id: "singapore", name: "Singapore", timeZoneIdentifier: "Asia/Singapore")
    static let hongKong = CityEntity(id: "hong-kong", name: "Hong Kong", timeZoneIdentifier: "Asia/Hong_Kong")
    static let seoul = CityEntity(id: "seoul", name: "Seoul", timeZoneIdentifier: "Asia/Seoul")
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

    /// Roster used by the in-app previews and custom roster initial state.
    static let defaults = [lisbon, newYork, tokyo, sydney]

    /// Shown before the user searches for a city.
    static let suggestions = [
        lisbon, newYork, tokyo, sydney, london,
        sanFrancisco, singapore, dubai
    ]

    static let all: [CityEntity] = [
        lisbon, london, paris, berlin, madrid, rome, amsterdam, stockholm, zurich,
        reykjavik, istanbul, moscow,
        newYork, sanFrancisco, losAngeles, chicago, denver, miami, toronto,
        mexicoCity, saoPaulo, rio, buenosAires, honolulu,
        dubai, mumbai, delhi, bangkok, singapore, hongKong, seoul, tokyo,
        sydney, auckland,
        cairo, lagos, nairobi, capeTown
    ].sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

    /// Resolves a saved entity ID. Unknown but valid time zones still render, which
    /// keeps widgets working if a city is removed from the catalog in a later build
    /// or when the user picks an IANA time zone identifier.
    static func city(id: String) -> CityEntity? {
        if let city = all.first(where: { $0.id == id }) {
            return city
        }

        let timeZoneIdentifier: String
        if id.hasPrefix("tz:") {
            timeZoneIdentifier = String(id.dropFirst(3))
        } else if TimeZone(identifier: id) != nil {
            timeZoneIdentifier = id
        } else {
            return nil
        }

        guard TimeZone(identifier: timeZoneIdentifier) != nil else { return nil }

        let fallbackName = friendlyCityName(for: timeZoneIdentifier)
        return CityEntity(id: id, name: fallbackName, timeZoneIdentifier: timeZoneIdentifier)
    }

    /// Formats an IANA identifier like "America/Argentina/Buenos_Aires" into "Buenos Aires".
    static func friendlyCityName(for timeZoneIdentifier: String) -> String {
        let lastComponent = timeZoneIdentifier
            .split(separator: "/")
            .last
            .map(String.init) ?? timeZoneIdentifier
        return lastComponent.replacingOccurrences(of: "_", with: " ")
    }

    /// Searches both the built-in catalog and all system IANA time zone identifiers.
    static func search(matching rawQuery: String) -> [CityEntity] {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return suggestions }

        let normalizedQuery = normalizeForSearch(trimmed)

        let catalogMatches = all.filter { city in
            normalizeForSearch(city.name).contains(normalizedQuery)
                || normalizeForSearch(city.timeZoneIdentifier).contains(normalizedQuery)
                || normalizeForSearch(city.id).contains(normalizedQuery)
        }

        var existingNames = Set(catalogMatches.map { normalizeForSearch($0.name) })
        var ianaMatches: [CityEntity] = []

        for identifier in TimeZone.knownTimeZoneIdentifiers {
            let friendly = friendlyCityName(for: identifier)
            let normalizedFriendly = normalizeForSearch(friendly)
            let normalizedIdentifier = normalizeForSearch(identifier)

            guard normalizedFriendly.contains(normalizedQuery)
                || normalizedIdentifier.contains(normalizedQuery)
            else {
                continue
            }

            guard existingNames.insert(normalizedFriendly).inserted else {
                continue
            }

            ianaMatches.append(
                CityEntity(
                    id: "tz:\(identifier)",
                    name: friendly,
                    timeZoneIdentifier: identifier
                )
            )
        }

        ianaMatches.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return catalogMatches + ianaMatches
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

    private static func normalizeForSearch(_ text: String) -> String {
        text
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

/// Persists the user's default city roster and preferred small widget style across
/// the host app and the WidgetKit extension.
final class RosterStore {
    static let shared = RosterStore()
    static let appGroupIdentifier = "group.com.maxgus.worldclock"

    private static let citiesKey = "defaultRosterCityIDs"
    private static let smallStyleKey = "defaultSmallWidgetStyle"
    private static let customizedKey = "hasCustomRoster"

    private let defaults: UserDefaults

    /// `true` only when this process can genuinely reach the shared app-group
    /// defaults. App groups are granted by a provisioning profile, so an
    /// ad-hoc signed build (the DMG) cannot use them: macOS still hands back a
    /// group container path, but that container is not writable and every
    /// process keeps a private copy of the suite. Probing for write access
    /// keeps the store honest instead of silently pretending to be shared.
    static let isSharedStoreAvailable: Bool = {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return false
        }
        return FileManager.default.isWritableFile(atPath: container.path)
    }()

    init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else if Self.isSharedStoreAvailable,
                  let shared = UserDefaults(suiteName: Self.appGroupIdentifier) {
            self.defaults = shared
        } else {
            // No usable app group: the store stays local to this process, so
            // the widget keeps falling back to the curated catalog defaults.
            self.defaults = .standard
        }
    }

    var hasCustomRoster: Bool {
        defaults.bool(forKey: Self.customizedKey)
    }

    var cities: [CityEntity] {
        get {
            guard let ids = defaults.stringArray(forKey: Self.citiesKey), !ids.isEmpty else {
                return CityCatalog.defaults
            }
            let resolved = ids.compactMap { CityCatalog.city(id: $0) }
            return CityCatalog.resolvedCities(
                configured: resolved.map { Optional($0) },
                fallbacks: CityCatalog.defaults,
                limit: 4
            )
        }
        set {
            let distinct = CityCatalog.resolvedCities(
                configured: newValue.map { Optional($0) },
                fallbacks: CityCatalog.defaults,
                limit: 4
            )
            defaults.set(distinct.map(\.id), forKey: Self.citiesKey)
            defaults.set(true, forKey: Self.customizedKey)
        }
    }

    var smallWidgetStyle: SmallWidgetStyle {
        get {
            guard let raw = defaults.string(forKey: Self.smallStyleKey),
                  let style = SmallWidgetStyle(rawValue: raw)
            else {
                return .focus
            }
            return style
        }
        set {
            defaults.set(newValue.rawValue, forKey: Self.smallStyleKey)
        }
    }

    func updateCity(_ city: CityEntity, at index: Int) {
        var current = cities
        guard current.indices.contains(index) else { return }
        if let existingIndex = current.firstIndex(where: { $0.id == city.id }), existingIndex != index {
            current.swapAt(index, existingIndex)
        } else {
            current[index] = city
        }
        cities = current
    }

    func resetToDefaults() {
        defaults.removeObject(forKey: Self.citiesKey)
        defaults.removeObject(forKey: Self.smallStyleKey)
        defaults.set(false, forKey: Self.customizedKey)
    }

    func fallbacks(forSmallStyle style: SmallWidgetStyle) -> [CityEntity] {
        if hasCustomRoster {
            return Array(cities.prefix(style.cityLimit))
        }
        switch style {
        case .focus:
            return CityCatalog.focusDefaults
        case .duo:
            return CityCatalog.duoDefaults
        case .list:
            return CityCatalog.listDefaults
        }
    }

    func trioFallbacks() -> [CityEntity] {
        hasCustomRoster ? Array(cities.prefix(3)) : CityCatalog.trioDefaults
    }

    func gridFallbacks() -> [CityEntity] {
        hasCustomRoster ? Array(cities.prefix(4)) : CityCatalog.gridDefaults
    }
}
