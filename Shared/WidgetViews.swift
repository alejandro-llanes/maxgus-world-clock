import SwiftUI
import WidgetKit

enum ClockTheme {
    static let ink = Color(red: 0.965, green: 0.973, blue: 0.988)
    static let ink2 = Color(red: 0.92, green: 0.945, blue: 1.0).opacity(0.62)
    static let ink3 = Color(red: 0.92, green: 0.945, blue: 1.0).opacity(0.40)
    static let hairline = Color.white.opacity(0.10)
}

/// The glass fill shared by the real widget and the in-app previews.
struct ClockTileBackground: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        if renderingMode == .vibrant {
            Color.white.opacity(0.04)
        } else {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)

                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.145, green: 0.160, blue: 0.225).opacity(0.86), location: 0.00),
                        .init(color: Color(red: 0.035, green: 0.040, blue: 0.065).opacity(0.94), location: 0.55),
                        .init(color: Color(red: 0.016, green: 0.020, blue: 0.036).opacity(0.97), location: 1.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [Color.white.opacity(0.055), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 240
                )

                RadialGradient(
                    colors: [Color(red: 0.24, green: 0.42, blue: 0.88).opacity(0.10), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 280
                )
            }
        }
    }
}

struct DayNightGlyph: View {
    let isNight: Bool
    var size: CGFloat = 13

    var body: some View {
        Image(systemName: isNight ? "moon" : "sun.max")
            .font(.system(size: size, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(ClockTheme.ink2)
            .accessibilityHidden(true)
    }
}

struct HomeBadge: View {
    var body: some View {
        Image(systemName: "location.fill")
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(ClockTheme.ink2)
            .accessibilityLabel("Current time zone")
    }
}

struct ClockTimeText: View {
    let clock: CityTime
    let size: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(clock.time)
                .font(.system(size: size, weight: .light))
                .tracking(-size * 0.048)
                .monospacedDigit()

            if let period = clock.period {
                Text(period)
                    .font(.system(size: size * 0.30, weight: .semibold))
                    .foregroundStyle(ClockTheme.ink2)
                    .padding(.leading, size * 0.09)
                    .padding(.top, size * 0.07)
            }
        }
        .foregroundStyle(ClockTheme.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .accessibilityLabel(clock.accessibilityDescription)
    }
}

struct FocusClockView: View {
    let clock: CityTime

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(clock.city.name)
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(-0.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if clock.isHome {
                        HomeBadge()
                    }
                }

                Spacer(minLength: 4)

                DayNightGlyph(isNight: clock.isNight, size: 13)
                    .padding(.top, 2)
            }

            Spacer(minLength: 4)

            ClockTimeText(clock: clock, size: 42)

            Spacer(minLength: 6)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(clock.footLine)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 4)

                Text(clock.offset)
                    .lineLimit(1)
                    .fixedSize()
            }
            .font(.system(size: 10.5, weight: .regular))
            .foregroundStyle(ClockTheme.ink2)
        }
        .padding(16)
        .foregroundStyle(ClockTheme.ink)
    }
}

/// Alternate 2×2 small widget layout: two stacked cities (Study B).
struct DuoClockView: View {
    let clocks: [CityTime]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(clocks.prefix(2).enumerated()), id: \.element.id) { index, clock in
                if index > 0 {
                    Rectangle()
                        .fill(ClockTheme.hairline)
                        .frame(height: 0.5)
                        .padding(.vertical, 8)
                }

                DuoRow(clock: clock)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .foregroundStyle(ClockTheme.ink)
    }
}

private struct DuoRow: View {
    let clock: CityTime

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(clock.city.name)
                    .font(.system(size: 12.5, weight: .semibold))
                    .tracking(-0.15)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if clock.isHome {
                    HomeBadge()
                }

                Spacer(minLength: 4)

                DayNightGlyph(isNight: clock.isNight, size: 11)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                ClockTimeText(clock: clock, size: 25)

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(clock.relativeDay)
                        .foregroundStyle(ClockTheme.ink3)
                    Text(clock.offset)
                        .foregroundStyle(ClockTheme.ink2)
                }
                .font(.system(size: 8.5, weight: .regular))
                .lineLimit(1)
                .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Alternate 2×2 small widget layout: three cities in a compact list (Study C).
struct CompactListClockView: View {
    let clocks: [CityTime]
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("World Clock")
                    .font(.system(size: 8.5, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(ClockTheme.ink3)

                Spacer(minLength: 4)

                Text(TimeFormatting.localDateLine(at: date))
                    .font(.system(size: 8.5, weight: .regular))
                    .tracking(0.5)
                    .foregroundStyle(ClockTheme.ink3)
                    .lineLimit(1)
            }
            .textCase(.uppercase)
            .padding(.bottom, 6)

            ForEach(Array(clocks.prefix(3).enumerated()), id: \.element.id) { index, clock in
                if index > 0 {
                    Rectangle()
                        .fill(ClockTheme.hairline)
                        .frame(height: 0.5)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(clock.city.name)
                            .font(.system(size: 12, weight: .medium))
                            .tracking(-0.15)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        if clock.isHome {
                            HomeBadge()
                        }
                    }

                    Spacer(minLength: 4)

                    ClockTimeText(clock: clock, size: 16)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .foregroundStyle(ClockTheme.ink)
    }
}

struct TrioClockView: View {
    let clocks: [CityTime]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(clocks.enumerated()), id: \.element.id) { index, clock in
                if index > 0 {
                    Rectangle()
                        .fill(ClockTheme.hairline)
                        .frame(width: 0.5)
                        .padding(.vertical, 2)
                }

                TrioColumn(clock: clock)
                    .padding(.leading, index == 0 ? 0 : 12)
                    .padding(.trailing, index == clocks.count - 1 ? 0 : 12)
            }
        }
        .padding(16)
    }
}

private struct TrioColumn: View {
    let clock: CityTime

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(clock.city.name)
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(-0.1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    if clock.isHome {
                        HomeBadge()
                    }
                }

                Spacer(minLength: 2)

                DayNightGlyph(isNight: clock.isNight, size: 11)
            }

            Spacer(minLength: 2)

            ClockTimeText(clock: clock, size: 27)

            Spacer(minLength: 2)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(clock.relativeDay)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 2)

                Text(clock.offset)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .font(.system(size: 9.5, weight: .regular))
            .foregroundStyle(ClockTheme.ink2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(ClockTheme.ink)
    }
}

struct GridClockView: View {
    let clocks: [CityTime]
    let date: Date

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("World Clock")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.55)
                    .foregroundStyle(ClockTheme.ink2)

                Spacer(minLength: 8)

                Text(TimeFormatting.localDateLine(at: date))
                    .font(.system(size: 10, weight: .regular))
                    .tracking(0.9)
                    .foregroundStyle(ClockTheme.ink3)
            }
            .textCase(.uppercase)
            .padding(.bottom, 14)

            Rectangle()
                .fill(ClockTheme.hairline)
                .frame(height: 0.5)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    gridCell(at: 0)
                    verticalRule
                    gridCell(at: 1)
                }
                .frame(maxHeight: .infinity)

                Rectangle()
                    .fill(ClockTheme.hairline)
                    .frame(height: 0.5)

                HStack(spacing: 0) {
                    gridCell(at: 2)
                    verticalRule
                    gridCell(at: 3)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(22)
    }

    private func gridCell(at index: Int) -> some View {
        Group {
            if clocks.indices.contains(index) {
                GridCell(clock: clocks[index])
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, index.isMultiple(of: 2) ? 0 : 16)
        .padding(.trailing, index.isMultiple(of: 2) ? 16 : 0)
        .padding(.top, index < 2 ? 15 : 13)
        .padding(.bottom, index < 2 ? 13 : 0)
    }

    private var verticalRule: some View {
        Rectangle()
            .fill(ClockTheme.hairline)
            .frame(width: 0.5)
    }
}

private struct GridCell: View {
    let clock: CityTime

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(clock.city.name)
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(-0.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if clock.isHome {
                        HomeBadge()
                    }
                }

                Spacer(minLength: 2)

                DayNightGlyph(isNight: clock.isNight, size: 12)
            }

            Spacer(minLength: 2)

            ClockTimeText(clock: clock, size: 38)

            Spacer(minLength: 2)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(clock.relativeDay)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 2)

                Text(clock.offset)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 10, weight: .regular))
            .foregroundStyle(ClockTheme.ink2)
        }
        .foregroundStyle(ClockTheme.ink)
    }
}

/// Renders a real-size widget view inside the host app, scaled for presentation.
struct ClockPreviewSurface<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    private let content: Content

    init(
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.height = height
        self.scale = scale
        self.content = content()
    }

    /// Continuous corners at 13% of tile width; 7.5% on 4×4 large tiles.
    private var cornerRadius: CGFloat {
        let ratio: CGFloat = (width >= 300 && height >= 300) ? 0.075 : 0.13
        return width * ratio
    }

    var body: some View {
        content
            .frame(width: width, height: height)
            .background { ClockTileBackground() }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(0.45), radius: 22, y: 14)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: width * scale, height: height * scale, alignment: .topLeading)
    }
}
