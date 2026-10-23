import Foundation
import XCTest

final class WorldClockTests: XCTestCase {

    // MARK: - CityCatalog Tests

    func testCatalogLookup() {
        let lisbon = CityCatalog.city(id: "lisbon")
        XCTAssertNotNil(lisbon)
        XCTAssertEqual(lisbon?.name, "Lisbon")
        XCTAssertEqual(lisbon?.timeZoneIdentifier, "Europe/Lisbon")

        let tokyo = CityCatalog.city(id: "tokyo")
        XCTAssertNotNil(tokyo)
        XCTAssertEqual(tokyo?.name, "Tokyo")
        XCTAssertEqual(tokyo?.timeZoneIdentifier, "Asia/Tokyo")
    }

    func testCatalogIDsAreUniqueAndResolve() {
        // Edit Widget stores these IDs as plain strings, so each must map back to one city.
        let ids = CityCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for id in ids {
            XCTAssertEqual(CityCatalog.city(id: id)?.id, id)
        }
        XCTAssertNil(CityCatalog.city(id: "not-a-city"))
    }

    func testCitySettingsResolveByNameOrLegacyID() {
        // Edit Widget stores names; builds before that stored IDs.
        XCTAssertEqual(CityCatalog.city(setting: "Buenos Aires")?.id, "buenos-aires")
        XCTAssertEqual(CityCatalog.city(setting: "Bogotá")?.id, "bogota")
        XCTAssertEqual(CityCatalog.city(setting: "buenos-aires")?.id, "buenos-aires")
        XCTAssertNil(CityCatalog.city(setting: "Atlantis"))

        let names = CityCatalog.all.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "names must be unique to be used as settings")
    }

    func testRegionsCoverTheCatalogOnce() {
        let grouped = CityCatalog.regions.flatMap(\.cities).map(\.id)
        XCTAssertEqual(grouped.sorted(), CityCatalog.all.map(\.id).sorted())
        XCTAssertEqual(CityCatalog.regions.map(\.name), ["Africa", "Americas", "Asia & Pacific", "Europe"])
    }

    // MARK: - Deduplication & Backfilling Tests

    func testResolvedCitiesDeduplicationDoesNotDropSlots() {
        let fallbacks = [CityCatalog.newYork, CityCatalog.tokyo, CityCatalog.sydney]

        // User sets the first slot to Tokyo, leaving second and third slots default.
        // Fallback[1] is also Tokyo! It must NOT drop the column down to 2 cities.
        let resolved = CityCatalog.resolvedCities(
            configured: [CityCatalog.tokyo, nil, nil],
            fallbacks: fallbacks,
            limit: 3
        )

        XCTAssertEqual(resolved.count, 3, "Trio widget must have exactly 3 cities")
        XCTAssertEqual(resolved[0].id, "tokyo")
        XCTAssertEqual(Set(resolved.map(\.id)).count, 3, "All 3 cities must be distinct")
    }

    func testResolvedCitiesSlotPlacementPreserved() {
        let fallbacks = [CityCatalog.newYork, CityCatalog.tokyo, CityCatalog.sydney]

        // User specifically placed Tokyo in slot 1 (index 1)
        let resolved = CityCatalog.resolvedCities(
            configured: [nil, CityCatalog.tokyo, nil],
            fallbacks: fallbacks,
            limit: 3
        )

        XCTAssertEqual(resolved.count, 3)
        XCTAssertEqual(resolved[1].id, "tokyo", "Slot 1 must contain Tokyo as requested")
        XCTAssertEqual(resolved[0].id, "new-york")
        XCTAssertEqual(resolved[2].id, "sydney")
    }

    func testResolvedCitiesLimit() {
        let fallbacks = CityCatalog.gridDefaults
        let resolvedSmall = CityCatalog.resolvedCities(configured: [], fallbacks: fallbacks, limit: 1)
        XCTAssertEqual(resolvedSmall.count, 1)

        let resolvedTrio = CityCatalog.resolvedCities(configured: [], fallbacks: fallbacks, limit: 3)
        XCTAssertEqual(resolvedTrio.count, 3)

        let resolvedGrid = CityCatalog.resolvedCities(configured: [], fallbacks: fallbacks, limit: 4)
        XCTAssertEqual(resolvedGrid.count, 4)
    }

    // MARK: - TimeFormatting Tests

    func testUtcOffsetFormatting() {
        let gmt = TimeZone(secondsFromGMT: 0)!
        let plus1 = TimeZone(secondsFromGMT: 3600)!
        let minus5 = TimeZone(secondsFromGMT: -18000)!
        let kolkata = TimeZone(identifier: "Asia/Kolkata")! // +05:30
        let kathmandu = TimeZone(identifier: "Asia/Kathmandu")! // +05:45

        let fixedDate = Date(timeIntervalSince1970: 1700000000)

        XCTAssertEqual(TimeFormatting.utcOffset(for: gmt, at: fixedDate), "UTC")
        XCTAssertEqual(TimeFormatting.utcOffset(for: plus1, at: fixedDate), "UTC+1")
        XCTAssertEqual(TimeFormatting.utcOffset(for: minus5, at: fixedDate), "UTC−5")
        XCTAssertEqual(TimeFormatting.utcOffset(for: kolkata, at: fixedDate), "UTC+5:30")
        XCTAssertEqual(TimeFormatting.utcOffset(for: kathmandu, at: fixedDate), "UTC+5:45")
    }

    func test12And24HourFormatting() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 21
        components.hour = 14
        components.minute = 30
        components.timeZone = TimeZone(identifier: "Europe/London")!
        let date = calendar.date(from: components)!

        let clock24 = TimeFormatting.clock(
            for: CityCatalog.london,
            at: date,
            referenceTimeZone: TimeZone(identifier: "Europe/London")!,
            use24Hour: true
        )
        XCTAssertEqual(clock24.time, "14:30")
        XCTAssertNil(clock24.period)

        let clock12 = TimeFormatting.clock(
            for: CityCatalog.london,
            at: date,
            referenceTimeZone: TimeZone(identifier: "Europe/London")!,
            use24Hour: false
        )
        XCTAssertEqual(clock12.time, "02:30")
        XCTAssertEqual(clock12.period, "PM")
    }

    func testRelativeDayCalculation() {
        let calendar = Calendar(identifier: .gregorian)
        var utcComponents = DateComponents()
        utcComponents.year = 2026
        utcComponents.month = 10
        utcComponents.day = 21
        utcComponents.hour = 23
        utcComponents.minute = 0
        utcComponents.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: utcComponents)!

        let utcZone = TimeZone(identifier: "UTC")!

        // Reykjavik is UTC+0 year-round -> at 23:00 Oct 21 -> Today
        let reykjavikClock = TimeFormatting.clock(
            for: CityCatalog.reykjavik,
            at: date,
            referenceTimeZone: utcZone,
            use24Hour: true
        )
        XCTAssertEqual(reykjavikClock.relativeDay, "Today")

        // London in late October is in BST (UTC+1) -> at 23:00 UTC it is 00:00 Oct 22 -> Tomorrow
        let londonClock = TimeFormatting.clock(
            for: CityCatalog.london,
            at: date,
            referenceTimeZone: utcZone,
            use24Hour: true
        )
        XCTAssertEqual(londonClock.relativeDay, "Tomorrow")

        // Tokyo is UTC+9 -> Oct 22, 08:00 -> Tomorrow
        let tokyoClock = TimeFormatting.clock(
            for: CityCatalog.tokyo,
            at: date,
            referenceTimeZone: utcZone,
            use24Hour: true
        )
        XCTAssertEqual(tokyoClock.relativeDay, "Tomorrow")

        // Honolulu is UTC-10 -> Oct 21, 13:00 -> Today
        // Now test Yesterday: Reference in Tokyo (Oct 22, 08:00), Honolulu is Oct 21 (Yesterday)
        let honoluluClockFromTokyo = TimeFormatting.clock(
            for: CityCatalog.honolulu,
            at: date,
            referenceTimeZone: TimeZone(identifier: "Asia/Tokyo")!,
            use24Hour: true
        )
        XCTAssertEqual(honoluluClockFromTokyo.relativeDay, "Yesterday")
    }

    func testDayNightCalculation() {
        let calendar = Calendar(identifier: .gregorian)
        let londonTz = TimeZone(identifier: "Europe/London")!

        func makeDate(hour: Int, minute: Int) -> Date {
            var comp = DateComponents()
            comp.year = 2026
            comp.month = 10
            comp.day = 21
            comp.hour = hour
            comp.minute = minute
            comp.timeZone = londonTz
            return calendar.date(from: comp)!
        }

        // Night before 06:00
        let nightMorning = TimeFormatting.clock(for: CityCatalog.london, at: makeDate(hour: 5, minute: 59))
        XCTAssertTrue(nightMorning.isNight)

        // Day starts at 06:00
        let dayStart = TimeFormatting.clock(for: CityCatalog.london, at: makeDate(hour: 6, minute: 0))
        XCTAssertFalse(dayStart.isNight)

        // Day during 12:00
        let dayNoon = TimeFormatting.clock(for: CityCatalog.london, at: makeDate(hour: 12, minute: 0))
        XCTAssertFalse(dayNoon.isNight)

        // Day ends before 19:00
        let dayEvening = TimeFormatting.clock(for: CityCatalog.london, at: makeDate(hour: 18, minute: 59))
        XCTAssertFalse(dayEvening.isNight)

        // Night starts at 19:00
        let nightEvening = TimeFormatting.clock(for: CityCatalog.london, at: makeDate(hour: 19, minute: 0))
        XCTAssertTrue(nightEvening.isNight)
    }

    func testHomeIndicator() {
        let londonTz = TimeZone(identifier: "Europe/London")!
        let clockHome = TimeFormatting.clock(
            for: CityCatalog.london,
            referenceTimeZone: londonTz
        )
        XCTAssertTrue(clockHome.isHome)

        let clockRemote = TimeFormatting.clock(
            for: CityCatalog.tokyo,
            referenceTimeZone: londonTz
        )
        XCTAssertFalse(clockRemote.isHome)
    }

    // MARK: - SmallWidgetStyle Tests

    func testSmallWidgetStyles() {
        XCTAssertEqual(SmallWidgetStyle.focus.cityLimit, 1)
        XCTAssertEqual(SmallWidgetStyle.duo.cityLimit, 2)
        XCTAssertEqual(SmallWidgetStyle.list.cityLimit, 3)
    }

    func testSmallStyleSettingsResolveByTitleOrLegacyRawValue() {
        XCTAssertEqual(SmallWidgetStyle(setting: "Compact List"), .list)
        XCTAssertEqual(SmallWidgetStyle(setting: "duo"), .duo)
        XCTAssertNil(SmallWidgetStyle(setting: "Grid"))
    }

    func testSmallWidgetStyleDefaultsFillEverySlot() {
        for style in SmallWidgetStyle.allCases {
            XCTAssertEqual(style.defaultCities.count, style.cityLimit, "\(style) defaults")
            XCTAssertEqual(Set(style.defaultCities.map(\.id)).count, style.cityLimit, "\(style) defaults are distinct")
        }
    }

    // MARK: - Formatter cache

    func testCachedFormattersKeepTimeZonesApart() {
        let date = Date(timeIntervalSince1970: 1_792_590_000) // 2026-10-21 13:40 UTC

        // Same format string, different zones: a shared cache must not mix them up.
        let london = TimeFormatting.clock(for: CityCatalog.london, at: date, use24Hour: true)
        let tokyo = TimeFormatting.clock(for: CityCatalog.tokyo, at: date, use24Hour: true)
        let londonAgain = TimeFormatting.clock(for: CityCatalog.london, at: date, use24Hour: true)

        XCTAssertEqual(london.time, "14:40")
        XCTAssertEqual(tokyo.time, "22:40")
        XCTAssertEqual(londonAgain.time, london.time)
    }
}
