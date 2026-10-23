import AppIntents
import Foundation

/// A city the user can place on a clock. `id` is a stable slug (not the time zone),
/// so cities that share a time zone — Miami and New York, for example — stay distinct.
struct CityEntity: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "City")
    static var defaultQuery = CityQuery()

    let id: String
    let name: String
    let timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.autoupdatingCurrent
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(timeZoneIdentifier.replacingOccurrences(of: "_", with: " "))"
        )
    }
}

enum SmallWidgetStyle: String, AppEnum, CaseIterable, Identifiable {
    case focus
    case duo
    case list

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .duo: return "Duo"
        case .list: return "Compact List"
        }
    }

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Small Widget Style")
    static var caseDisplayRepresentations: [SmallWidgetStyle: DisplayRepresentation] = [
        .focus: DisplayRepresentation(
            title: "Focus",
            subtitle: "One city with large numerals"
        ),
        .duo: DisplayRepresentation(
            title: "Duo",
            subtitle: "Two cities stacked"
        ),
        .list: DisplayRepresentation(
            title: "Compact List",
            subtitle: "Three cities in a compact list"
        )
    ]

    var cityLimit: Int {
        switch self {
        case .focus: return 1
        case .duo: return 2
        case .list: return 3
        }
    }
}

struct CityQuery: EntityStringQuery {
    func entities(for identifiers: [CityEntity.ID]) async throws -> [CityEntity] {
        identifiers.compactMap { CityCatalog.city(id: $0) }
    }

    func entities(matching string: String) async throws -> [CityEntity] {
        CityCatalog.search(matching: string)
    }

    func suggestedEntities() async throws -> [CityEntity] {
        CityCatalog.suggestions
    }

    func defaultResult() async -> CityEntity? {
        RosterStore.shared.cities.first ?? CityCatalog.lisbon
    }
}
