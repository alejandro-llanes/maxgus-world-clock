import Foundation

/// Everything a tile needs for one city at one moment.
struct CityTime: Identifiable {
    let city: CityEntity
    let time: String
    let period: String?
    let dateLine: String
    let footLine: String
    let relativeDay: String
    let offset: String
    let isNight: Bool
    let isHome: Bool

    var id: String { city.id }

    var accessibilityDescription: String {
        var parts = [city.name, time]
        if let period {
            parts.append(period)
        }
        parts.append(contentsOf: [relativeDay, offset])
        return parts.joined(separator: ", ")
    }
}

enum TimeFormatting {
    /// Follows the viewer's 12/24-hour preference rather than hard-coding a format.
    static var uses24Hour: Bool {
        let template = DateFormatter.dateFormat(
            fromTemplate: "j",
            options: 0,
            locale: .autoupdatingCurrent
        ) ?? "H"
        return template.contains("H") || template.contains("k")
    }

    static func clock(
        for city: CityEntity,
        at date: Date = .now,
        referenceTimeZone: TimeZone = .autoupdatingCurrent,
        use24Hour: Bool? = nil
    ) -> CityTime {
        let timeZone = city.timeZone
        let is24Hour = use24Hour ?? uses24Hour

        let time = formatter(is24Hour ? "HH:mm" : "hh:mm", timeZone: timeZone)
            .string(from: date)
        let period = is24Hour
            ? nil
            : formatter("a", timeZone: timeZone).string(from: date)

        let dateLine = formatter("EEE d MMM", timeZone: timeZone).string(from: date)
        let dayMonth = formatter("d MMM", timeZone: timeZone).string(from: date)
        let weekday = formatter("EEE", timeZone: timeZone).string(from: date)

        let cityKey = dayKey(for: date, in: timeZone)
        let localKey = dayKey(for: date, in: referenceTimeZone)

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = referenceTimeZone
        let localStart = localCalendar.startOfDay(for: date)
        let tomorrowKey = localCalendar.date(byAdding: .day, value: 1, to: localStart)
            .map { dayKey(for: $0, in: referenceTimeZone) }
        let yesterdayKey = localCalendar.date(byAdding: .day, value: -1, to: localStart)
            .map { dayKey(for: $0, in: referenceTimeZone) }

        let relativeDay: String
        let footLine: String

        if cityKey == localKey {
            relativeDay = "Today"
            footLine = dateLine
        } else if cityKey == tomorrowKey {
            relativeDay = "Tomorrow"
            footLine = "Tomorrow · \(dayMonth)"
        } else if cityKey == yesterdayKey {
            relativeDay = "Yesterday"
            footLine = "Yesterday · \(dayMonth)"
        } else {
            relativeDay = weekday
            footLine = dateLine
        }

        var cityCalendar = Calendar(identifier: .gregorian)
        cityCalendar.timeZone = timeZone
        let hour = cityCalendar.component(.hour, from: date)

        return CityTime(
            city: city,
            time: time,
            period: period,
            dateLine: dateLine,
            footLine: footLine,
            relativeDay: relativeDay,
            offset: utcOffset(for: timeZone, at: date),
            isNight: hour < 6 || hour >= 19,
            isHome: timeZone.identifier == referenceTimeZone.identifier
        )
    }

    static func localDateLine(
        at date: Date = .now,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        formatter("EEE d MMM", timeZone: timeZone).string(from: date)
    }

    static func utcOffset(for timeZone: TimeZone, at date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let totalMinutes = abs(seconds) / 60

        guard totalMinutes > 0 else { return "UTC" }

        let sign = seconds < 0 ? "−" : "+"
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let minuteSuffix = minutes == 0 ? "" : String(format: ":%02d", minutes)

        return "UTC\(sign)\(hours)\(minuteSuffix)"
    }

    private static func dayKey(for date: Date, in timeZone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return (parts.year ?? 0) * 10_000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
    }

    private static let formatters = FormatterCache()

    private static func formatter(_ format: String, timeZone: TimeZone) -> DateFormatter {
        formatters.formatter(format, timeZone: timeZone)
    }
}

/// DateFormatter is expensive to create and every tile asks for several per city,
/// so formatters are reused per format and time zone. Formatting itself is thread-safe.
private final class FormatterCache: @unchecked Sendable {
    private let lock = NSLock()
    private var cache: [String: DateFormatter] = [:]

    func formatter(_ format: String, timeZone: TimeZone) -> DateFormatter {
        let key = "\(timeZone.identifier)|\(format)"
        lock.lock()
        defer { lock.unlock() }

        if let cached = cache[key] {
            return cached
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        // Pin the zone: an autoupdating zone would drift away from its cache key
        // if the Mac's time zone changes.
        formatter.timeZone = TimeZone(identifier: timeZone.identifier) ?? timeZone
        formatter.dateFormat = format
        cache[key] = formatter
        return formatter
    }
}
