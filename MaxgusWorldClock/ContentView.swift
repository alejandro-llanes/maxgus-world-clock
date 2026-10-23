import SwiftUI

struct ContentView: View {
    /// Preview-only: each placed widget picks its own style in Edit Widget.
    @State private var smallStyle: SmallWidgetStyle = .focus

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    masthead
                    previewSection
                    installCard
                    footer
                }
                .padding(38)
                .frame(maxWidth: 960, alignment: .leading)
            }
        }
        .frame(minWidth: 860, minHeight: 700)
    }

    // MARK: Header

    private var masthead: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 9) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.81, green: 0.88, blue: 1.0),
                                    Color(red: 0.40, green: 0.60, blue: 0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 10, height: 10)
                        .shadow(color: Color(red: 0.45, green: 0.65, blue: 1.0).opacity(0.7), radius: 7)

                    Text("MAXGUS / WORLD CLOCK")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(ClockTheme.ink2)
                }

                Text("Every timezone,\nat a glance.")
                    .font(.system(size: 46, weight: .light))
                    .tracking(-2.0)
                    .lineSpacing(-1)
                    .foregroundStyle(ClockTheme.ink)

                Text("A quiet glass tile for your desktop. City first, time large, context close by.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ClockTheme.ink2)
                    .frame(maxWidth: 460, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            LiveBadge()
                .padding(.top, 2)
        }
    }

    // MARK: Previews

    /// Each preview shows the cities a freshly placed widget of that size starts with.
    private var previewSection: some View {
        TimelineView(.everyMinute) { context in
            let clocks = { (cities: [CityEntity]) in
                cities.map { TimeFormatting.clock(for: $0, at: context.date) }
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    sectionLabel("The widget", trailing: "2×2  ·  4×2  ·  4×4")
                    Spacer()
                    smallStylePicker
                }

                HStack(alignment: .top, spacing: 20) {
                    // 2×2 Small Widget
                    VStack(alignment: .leading, spacing: 10) {
                        ClockPreviewSurface(width: 158, height: 158, scale: 1.15) {
                            let small = clocks(smallStyle.defaultCities)
                            switch smallStyle {
                            case .focus:
                                FocusClockView(clock: small[0])
                            case .duo:
                                DuoClockView(clocks: small)
                            case .list:
                                CompactListClockView(clocks: small, date: context.date)
                            }
                        }
                        previewCaption("2×2 \(smallStyle.title)", detail: "158 × 158 pt")
                    }

                    // 4×2 Medium Widget
                    VStack(alignment: .leading, spacing: 10) {
                        ClockPreviewSurface(width: 338, height: 158, scale: 1.15) {
                            TrioClockView(clocks: clocks(CityCatalog.trioDefaults))
                        }
                        previewCaption("4×2 Trio", detail: "338 × 158 pt")
                    }

                    // 4×4 Large Widget
                    VStack(alignment: .leading, spacing: 10) {
                        ClockPreviewSurface(width: 338, height: 338, scale: 0.68) {
                            GridClockView(clocks: clocks(CityCatalog.gridDefaults), date: context.date)
                        }
                        previewCaption("4×4 Grid", detail: "338 × 338 pt")
                    }
                }
            }
        }
    }

    private var smallStylePicker: some View {
        HStack(spacing: 3) {
            ForEach(SmallWidgetStyle.allCases) { style in
                Button {
                    smallStyle = style
                } label: {
                    Text(style.title)
                        .font(.system(size: 11, weight: smallStyle == style ? .semibold : .regular))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .foregroundStyle(smallStyle == style ? ClockTheme.ink : ClockTheme.ink3)
                        .background {
                            if smallStyle == style {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.12))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.04)))
    }

    // MARK: Instructions

    private var installCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Put it on your desktop")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ClockTheme.ink)

                Spacer()

                Image(systemName: "macwindow")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ClockTheme.ink3)
            }

            VStack(spacing: 0) {
                stepRow(
                    number: 1,
                    text: "Click your desktop, then choose **Edit Widgets…**"
                )
                stepDivider
                stepRow(
                    number: 2,
                    text: "Search for **Maxgus World Clock** and drag the size you want."
                )
                stepDivider
                stepRow(
                    number: 3,
                    text: "Right-click the widget and choose **Edit Widget** to pick its cities."
                )
            }
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.75)
        }
    }

    private func stepRow(number: Int, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Text("\(number)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(ClockTheme.ink2)
                .frame(width: 21, height: 21)
                .background(Circle().fill(Color.white.opacity(0.055)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.09), lineWidth: 0.5))

            Text(text)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundStyle(ClockTheme.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 11)
    }

    private var stepDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 34)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 0.5)

            HStack(spacing: 16) {
                Text("Follows your Mac's 12/24-hour setting.")
                Spacer()
                Text("Glass · SF Pro · WidgetKit")
            }
            .font(.system(size: 10.5, weight: .regular))
            .foregroundStyle(ClockTheme.ink3)
        }
        .padding(.top, 4)
    }

    // MARK: Bits

    private func sectionLabel(_ title: String, trailing: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(ClockTheme.ink2)

            Spacer(minLength: 8)

            if let trailing {
                Text(trailing)
                    .font(.system(size: 10, weight: .regular))
                    .tracking(0.6)
                    .foregroundStyle(ClockTheme.ink3)
            }
        }
    }

    private func previewCaption(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ClockTheme.ink)
            Text(detail)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(ClockTheme.ink3)
        }
        .padding(.leading, 2)
    }
}

private struct LiveBadge: View {
    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Color(red: 0.56, green: 0.89, blue: 0.66))
                .frame(width: 5, height: 5)
                .shadow(color: Color(red: 0.56, green: 0.89, blue: 0.66).opacity(0.8), radius: 5)

            Text("Live preview")
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(ClockTheme.ink2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule().fill(Color.white.opacity(0.045))
        }
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        }
    }
}

private struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.028, green: 0.032, blue: 0.044)

            RadialGradient(
                colors: [Color(red: 0.15, green: 0.23, blue: 0.46).opacity(0.40), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 760
            )

            RadialGradient(
                colors: [Color(red: 0.26, green: 0.14, blue: 0.34).opacity(0.28), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 640
            )

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
