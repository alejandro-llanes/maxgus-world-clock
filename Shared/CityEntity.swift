import Foundation

/// A city the user can place on a clock. `id` is a stable slug (not the time zone),
/// so cities that share a time zone — Miami and New York, for example — stay distinct.
struct CityEntity: Identifiable, Hashable {
    let id: String
    let name: String
    let timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.autoupdatingCurrent
    }

    /// Picker grouping, taken from the time zone's top-level area.
    var region: String {
        switch timeZoneIdentifier.prefix(while: { $0 != "/" }) {
        case "America": return "Americas"
        case "Europe", "Atlantic": return "Europe"
        case "Africa": return "Africa"
        default: return "Asia & Pacific"
        }
    }
}

/// The 2×2 layouts. Edit Widget stores the raw value as a plain string; see
/// `CityOptionsProvider` in the widget for why these aren't an AppEnum.
enum SmallWidgetStyle: String, CaseIterable, Identifiable {
    case focus
    case duo
    case list

    var id: String { rawValue }

    /// Matches a style saved by Edit Widget: its title, or the raw value earlier builds stored.
    init?(setting: String) {
        guard let style = Self.allCases.first(where: { $0.title == setting || $0.rawValue == setting }) else {
            return nil
        }
        self = style
    }

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .duo: return "Duo"
        case .list: return "Compact List"
        }
    }

    var subtitle: String {
        switch self {
        case .focus: return "One city with large numerals"
        case .duo: return "Two cities stacked"
        case .list: return "Three cities in a compact list"
        }
    }

    var cityLimit: Int {
        switch self {
        case .focus: return 1
        case .duo: return 2
        case .list: return 3
        }
    }

    var defaultCities: [CityEntity] {
        switch self {
        case .focus: return CityCatalog.focusDefaults
        case .duo: return CityCatalog.duoDefaults
        case .list: return CityCatalog.listDefaults
        }
    }
}
