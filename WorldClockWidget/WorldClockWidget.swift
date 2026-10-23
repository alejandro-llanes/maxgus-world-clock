import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Configuration

struct WorldClockConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "World Clock"
    static var description = IntentDescription("Choose the cities shown on your clock.")

    @Parameter(
        title: "Small widget style",
        description: "Layout for the 2×2 small widget.",
        default: .focus
    )
    var smallStyle: SmallWidgetStyle

    @Parameter(
        title: "Main city",
        description: "The city shown by every widget size."
    )
    var firstCity: CityEntity?

    @Parameter(
        title: "Second city",
        description: "Adds a city to Duo, Compact List, medium, and large widgets."
    )
    var secondCity: CityEntity?

    @Parameter(
        title: "Third city",
        description: "Adds a city to Compact List, medium, and large widgets."
    )
    var thirdCity: CityEntity?

    @Parameter(
        title: "Fourth city",
        description: "Adds a city to the large widget."
    )
    var fourthCity: CityEntity?

    init() {
        self.smallStyle = RosterStore.shared.smallWidgetStyle
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
        let style = RosterStore.shared.smallWidgetStyle
        return WorldClockEntry(
            date: .now,
            cities: RosterStore.shared.fallbacks(forSmallStyle: style),
            smallStyle: style
        )
    }

    func snapshot(
        for configuration: WorldClockConfigurationIntent,
        in context: Context
    ) async -> WorldClockEntry {
        WorldClockEntry(
            date: .now,
            cities: resolvedCities(for: configuration, in: context.family),
            smallStyle: configuration.smallStyle
        )
    }

    func timeline(
        for configuration: WorldClockConfigurationIntent,
        in context: Context
    ) async -> Timeline<WorldClockEntry> {
        let cities = resolvedCities(for: configuration, in: context.family)
        let smallStyle = configuration.smallStyle

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
        let limit: Int
        let fallbacks: [CityEntity]

        switch family {
        case .systemSmall:
            limit = configuration.smallStyle.cityLimit
            fallbacks = RosterStore.shared.fallbacks(forSmallStyle: configuration.smallStyle)
        case .systemMedium:
            limit = 3
            fallbacks = RosterStore.shared.trioFallbacks()
        default:
            limit = 4
            fallbacks = RosterStore.shared.gridFallbacks()
        }

        let configured = [
            configuration.firstCity,
            configuration.secondCity,
            configuration.thirdCity,
            configuration.fourthCity
        ]

        return CityCatalog.resolvedCities(
            configured: configured,
            fallbacks: fallbacks,
            limit: limit
        )
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
