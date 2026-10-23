import SwiftUI
import WidgetKit

final class AppViewModel: ObservableObject {
    @Published var smallStyle: SmallWidgetStyle = RosterStore.shared.smallWidgetStyle
    @Published var rosterCities: [CityEntity] = RosterStore.shared.cities
    @Published var editingSlotIndex: Int? = nil

    func updateCity(_ city: CityEntity, at index: Int) {
        RosterStore.shared.updateCity(city, at: index)
        rosterCities = RosterStore.shared.cities
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setSmallStyle(_ style: SmallWidgetStyle) {
        smallStyle = style
        RosterStore.shared.smallWidgetStyle = style
        WidgetCenter.shared.reloadAllTimelines()
    }

    func resetToDefaults() {
        RosterStore.shared.resetToDefaults()
        rosterCities = RosterStore.shared.cities
        smallStyle = RosterStore.shared.smallWidgetStyle
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct ContentView: View {
    @ObservedObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    masthead
                    previewSection
                    rosterSection
                    installCard
                    footer
                }
                .padding(38)
                .frame(maxWidth: 960, alignment: .leading)
            }
        }
        .frame(minWidth: 860, minHeight: 700)
        .sheet(item: Binding<SlotItem?>(
            get: { viewModel.editingSlotIndex.map { SlotItem(index: $0) } },
            set: { viewModel.editingSlotIndex = $0?.index }
        )) { item in
            CityPickerSheet(
                slotIndex: item.index,
                currentCity: viewModel.rosterCities[item.index],
                onSelect: { chosen in
                    viewModel.updateCity(chosen, at: item.index)
                    viewModel.editingSlotIndex = nil
                },
                onDismiss: {
                    viewModel.editingSlotIndex = nil
                }
            )
        }
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

    private var previewSection: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let clocks = viewModel.rosterCities.map { TimeFormatting.clock(for: $0, at: context.date) }
            let firstClock = clocks.first ?? TimeFormatting.clock(for: CityCatalog.lisbon, at: context.date)

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
                            switch viewModel.smallStyle {
                            case .focus:
                                FocusClockView(clock: firstClock)
                            case .duo:
                                DuoClockView(clocks: Array(clocks.prefix(2)))
                            case .list:
                                CompactListClockView(clocks: Array(clocks.prefix(3)), date: context.date)
                            }
                        }
                        previewCaption("2×2 \(viewModel.smallStyle.title)", detail: "158 × 158 pt")
                    }

                    // 4×2 Medium Widget
                    VStack(alignment: .leading, spacing: 10) {
                        ClockPreviewSurface(width: 338, height: 158, scale: 1.15) {
                            TrioClockView(clocks: Array(clocks.prefix(3)))
                        }
                        previewCaption("4×2 Trio", detail: "338 × 158 pt")
                    }

                    // 4×4 Large Widget
                    VStack(alignment: .leading, spacing: 10) {
                        ClockPreviewSurface(width: 338, height: 338, scale: 0.68) {
                            GridClockView(clocks: Array(clocks.prefix(4)), date: context.date)
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
                    viewModel.setSmallStyle(style)
                } label: {
                    Text(style.title)
                        .font(.system(size: 11, weight: viewModel.smallStyle == style ? .semibold : .regular))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .foregroundStyle(viewModel.smallStyle == style ? ClockTheme.ink : ClockTheme.ink3)
                        .background {
                            if viewModel.smallStyle == style {
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

    // MARK: Roster Settings

    private var rosterSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Default City Roster")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ClockTheme.ink)

                Spacer()

                if RosterStore.shared.hasCustomRoster {
                    Button("Reset to Defaults") {
                        viewModel.resetToDefaults()
                    }
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(red: 0.45, green: 0.65, blue: 1.0))
                    .buttonStyle(.plain)
                }
            }

            Text("These cities populate newly placed desktop widgets when slots are left unconfigured.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(ClockTheme.ink2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    let city = viewModel.rosterCities.indices.contains(index) ? viewModel.rosterCities[index] : CityCatalog.defaults[index]
                    Button {
                        viewModel.editingSlotIndex = index
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(ClockTheme.ink3)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Color.white.opacity(0.06)))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(city.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ClockTheme.ink)
                                Text(city.timeZoneIdentifier.replacingOccurrences(of: "_", with: " "))
                                    .font(.system(size: 10.5, weight: .regular))
                                    .foregroundStyle(ClockTheme.ink3)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(ClockTheme.ink3)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.75)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.75)
        }
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

// MARK: - City Picker

struct SlotItem: Identifiable {
    let index: Int
    var id: Int { index }
}

private final class CitySearchViewModel: ObservableObject {
    @Published var query: String = ""

    var results: [CityEntity] {
        CityCatalog.search(matching: query)
    }
}

private struct CityPickerSheet: View {
    let slotIndex: Int
    let currentCity: CityEntity
    let onSelect: (CityEntity) -> Void
    let onDismiss: () -> Void

    @ObservedObject private var searchModel = CitySearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Select City \(slotIndex + 1)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ClockTheme.ink)
                    Text("Search ~40 curated cities or any IANA time zone identifier")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(ClockTheme.ink3)
                }

                Spacer()

                Button("Done") {
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(18)

            // Search Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ClockTheme.ink3)

                TextField("Search cities, countries, or time zones (e.g. Tokyo, Bogota, America/Warsaw)…", text: $searchModel.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(ClockTheme.ink)

                if !searchModel.query.isEmpty {
                    Button {
                        searchModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(ClockTheme.ink3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)))
            .padding(.horizontal, 18)
            .padding(.bottom, 12)

            Rectangle()
                .fill(ClockTheme.hairline)
                .frame(height: 0.5)

            // List of matching cities
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(searchModel.results) { city in
                        Button {
                            onSelect(city)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(city.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(ClockTheme.ink)
                                        if city.id == currentCity.id {
                                            Text("Current")
                                                .font(.system(size: 9.5, weight: .semibold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color.white.opacity(0.1)))
                                                .foregroundStyle(ClockTheme.ink2)
                                        }
                                    }

                                    Text(city.timeZoneIdentifier.replacingOccurrences(of: "_", with: " "))
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(ClockTheme.ink3)
                                }

                                Spacer()

                                let previewTime = TimeFormatting.clock(for: city)
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(previewTime.time)
                                        .font(.system(size: 13, weight: .light))
                                        .monospacedDigit()
                                        .foregroundStyle(ClockTheme.ink)
                                    Text(previewTime.offset)
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundStyle(ClockTheme.ink3)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background {
                                if city.id == currentCity.id {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .frame(width: 520, height: 460)
        .background {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.12)
                RadialGradient(
                    colors: [Color(red: 0.18, green: 0.26, blue: 0.50).opacity(0.3), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 400
                )
            }
        }
    }
}
