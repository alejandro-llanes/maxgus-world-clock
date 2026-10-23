import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Configuration

struct WorldClockConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "World Clock"
    static var description = IntentDescription("Choose the cities shown on your clock.")

    // Optional because a String default plus an options provider needs macOS 26;
    // unset means Focus (see `style`, and the provider's default).
    @Parameter(title: "Small widget style", optionsProvider: SmallStyleOptionsProvider())
    var smallStyle: String?

    // Renamed from firstCity…fourthCity when cities stopped being an AppEntity, so values
    // saved by the old entity parameters are ignored instead of decoded as the wrong type.

    @Parameter(
        title: "Main city",
        description: "Leave empty to use this size's default.",
        optionsProvider: CityOptionsProvider()
    )
    var city1: String?

    @Parameter(
        title: "Second city",
        description: "Leave empty to use this size's default.",
        optionsProvider: CityOptionsProvider()
    )
    var city2: String?

    @Parameter(
        title: "Third city",
        description: "Leave empty to use this size's default.",
        optionsProvider: CityOptionsProvider()
    )
    var city3: String?

    @Parameter(
        title: "Fourth city",
        description: "Leave empty to use this size's default.",
        optionsProvider: CityOptionsProvider()
    )
    var city4: String?

    /// Edit Widget lists only the settings the placed size and style actually use.
    static var parameterSummary: some ParameterSummary {
        Switch(.widgetFamily) {
            Case(.systemSmall) {
                Switch(\.$smallStyle) {
                    Case(["Duo", "duo"]) {
                        Summary { \.$smallStyle; \.$city1; \.$city2 }
                    }
                    Case(["Compact List", "list"]) {
                        Summary { \.$smallStyle; \.$city1; \.$city2; \.$city3 }
                    }
                    DefaultCase {
                        Summary { \.$smallStyle; \.$city1 }
                    }
                }
            }
            Case(.systemMedium) {
                Summary { \.$city1; \.$city2; \.$city3 }
            }
            DefaultCase {
                Summary { \.$city1; \.$city2; \.$city3; \.$city4 }
            }
        }
    }
}

/// Edit Widget's city picker. Settings are plain strings (city names here) rather than an
/// AppEntity or AppEnum: macOS decodes custom App Intents types through linkd, which
/// rejects bundles without a Team ID, so in an ad-hoc build those values always arrive
/// empty. Strings are a built-in type and decode inside the widget. Storing the name
/// rather than an ID keeps the picker readable even when it shows the raw value.
struct CityOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        IntentItemCollection(
            promptLabel: "Search cities",
            sections: CityCatalog.regions.map { region in
                IntentItemSection("\(region.name)", items: region.cities.map { city in
                    IntentItem(
                        city.name,
                        title: "\(city.name)",
                        subtitle: "\(city.timeZoneIdentifier.replacingOccurrences(of: "_", with: " "))"
                    )
                })
            }
        )
    }
}

struct SmallStyleOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        IntentItemCollection(sections: [
            IntentItemSection(items: SmallWidgetStyle.allCases.map { style in
                IntentItem(style.title, title: "\(style.title)", subtitle: "\(style.subtitle)")
            })
        ])
    }

    func defaultResult() async -> String? {
        SmallWidgetStyle.focus.title
    }
}

extension WorldClockConfigurationIntent {
    var style: SmallWidgetStyle {
        smallStyle.flatMap(SmallWidgetStyle.init(setting:)) ?? .focus
    }
}

// MARK: - Timeline

struct WorldClockEntry: TimelineEntry {
    let date: Date
    let cities: [CityEntity]
    let smallStyle: SmallWidgetStyle
}

struct WorldClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WorldClockEntry {
        WorldClockEntry(
            date: .now,
            cities: Self.layout(for: context.family, smallStyle: .focus).defaults,
            smallStyle: .focus
        )
    }

    func snapshot(
        for configuration: WorldClockConfigurationIntent,
        in context: Context
    ) async -> WorldClockEntry {
        WorldClockEntry(
            date: .now,
            cities: resolvedCities(for: configuration, in: context.family),
            smallStyle: configuration.style
        )
    }

    func timeline(
        for configuration: WorldClockConfigurationIntent,
        in context: Context
    ) async -> Timeline<WorldClockEntry> {
        let cities = resolvedCities(for: configuration, in: context.family)
        let smallStyle = configuration.style

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let now = Date()
        let start = calendar.date(bySetting: .second, value: 0, of: now) ?? now

        // One entry per minute keeps the minute, day label, and UTC offset exact.
        // WidgetKit stops asking for entries when this timeline runs out.
        let entries: [WorldClockEntry] = (0...60).map { minute in
            WorldClockEntry(
                date: start.addingTimeInterval(TimeInterval(minute * 60)),
                cities: cities,
                smallStyle: smallStyle
            )
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    func resolvedCities(
        for configuration: WorldClockConfigurationIntent,
        in family: WidgetFamily
    ) -> [CityEntity] {
        let layout = Self.layout(for: family, smallStyle: configuration.style)
        let configured = [
            configuration.city1,
            configuration.city2,
            configuration.city3,
            configuration.city4
        ].map { $0.flatMap(CityCatalog.city(setting:)) }

        return CityCatalog.resolvedCities(
            configured: configured,
            fallbacks: layout.defaults,
            limit: layout.limit
        )
    }

    /// How many cities a family shows, and which ones fill slots the user left empty.
    private static func layout(
        for family: WidgetFamily,
        smallStyle: SmallWidgetStyle
    ) -> (limit: Int, defaults: [CityEntity]) {
        switch family {
        case .systemSmall:
            return (smallStyle.cityLimit, smallStyle.defaultCities)
        case .systemMedium:
            return (3, CityCatalog.trioDefaults)
        default:
            return (4, CityCatalog.gridDefaults)
        }
    }
}

// MARK: - Widget

struct WorldClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WorldClockEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                switch entry.smallStyle {
                case .focus:
                    FocusClockView(clock: clocks[0])
                case .duo:
                    DuoClockView(clocks: Array(clocks.prefix(2)))
                case .list:
                    CompactListClockView(clocks: Array(clocks.prefix(3)), date: entry.date)
                }
            case .systemMedium:
                TrioClockView(clocks: Array(clocks.prefix(3)))
            default:
                GridClockView(clocks: Array(clocks.prefix(4)), date: entry.date)
            }
        }
        .containerBackground(for: .widget) {
            ClockTileBackground()
        }
    }

    private var clocks: [CityTime] {
        let cities = entry.cities.isEmpty ? CityCatalog.focusDefaults : entry.cities
        return cities.map { TimeFormatting.clock(for: $0, at: entry.date) }
    }
}

struct WorldClockWidget: Widget {
    let kind = "WorldClockWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: WorldClockConfigurationIntent.self,
            provider: WorldClockProvider()
        ) { entry in
            WorldClockWidgetView(entry: entry)
        }
        .configurationDisplayName("World Clock")
        .description("Times for the cities you care about, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct WorldClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorldClockWidget()
    }
}
