import SwiftUI
import WidgetKit

struct ArsoWidgetEntry: TimelineEntry {
    let date: Date
    let content: WidgetWeatherContent
}

struct ArsoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ArsoWidgetEntry {
        ArsoWidgetEntry(date: .now, content: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ArsoWidgetEntry) -> Void) {
        Task {
            let content = await WidgetWeatherLoader().loadContent()
            completion(ArsoWidgetEntry(date: .now, content: content))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArsoWidgetEntry>) -> Void) {
        Task {
            let content = await WidgetWeatherLoader().loadContent()
            let entry = ArsoWidgetEntry(date: .now, content: content)
            let defaults = WidgetSharedStore.defaults
            let enabled = defaults?.object(forKey: WidgetSharedStore.Keys.autoRefreshEnabled) as? Bool ?? true
            let hours = defaults?.integer(forKey: "autoRefreshHours") ?? 1
            let interval = TimeInterval(([1, 3, 6].contains(hours) ? hours : 1) * 3600)
            completion(Timeline(entries: [entry], policy: enabled ? .after(.now.addingTimeInterval(interval)) : .never))
        }
    }
}

struct ArsoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ArsoWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallCurrentWidgetView(content: entry.content)
            case .systemMedium:
                MediumForecastWidgetView(content: entry.content, maxDays: 5)
            case .systemLarge:
                LargeForecastWidgetView(content: entry.content, maxDays: 5)
            default:
                SmallCurrentWidgetView(content: entry.content)
            }
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
        .widgetContainerBackground(condition: entry.content.currentCondition)
    }
}

struct ArsoCurrentWidget: Widget {
    let kind = "ArsoCurrentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArsoWidgetProvider()) { entry in
            ArsoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ARSO trenutno")
        .description("Trenutna temperatura in stanje za tvojo lokacijo.")
        .supportedFamilies([.systemSmall])
    }
}

struct ArsoForecastMediumWidget: Widget {
    let kind = "ArsoForecastMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArsoWidgetProvider()) { entry in
            ArsoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ARSO 5 dni")
        .description("Petdnevna grafična napoved za izbrano lokacijo.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct ArsoForecastLargeWidget: Widget {
    let kind = "ArsoForecastLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArsoWidgetProvider()) { entry in
            ArsoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ARSO podrobno")
        .description("Petdnevna napoved, opozorila in kratek uporaben povzetek.")
        .supportedFamilies([.systemLarge])
    }
}

private struct SmallCurrentWidgetView: View {
    let content: WidgetWeatherContent

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WeatherGlyph(condition: content.currentCondition, size: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.locationName)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(content.isFallbackLocation ? "Zadnji podatki" : "Izbrana lokacija")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                Text(content.currentTemperatureText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(content.currentSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.trailing, 30)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct MediumForecastWidgetView: View {
    let content: WidgetWeatherContent
    let maxDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            widgetHeader
            HStack(spacing: 8) {
                ForEach(content.dailyForecast.prefix(maxDays)) { day in
                    WidgetForecastColumn(day: day, isCompact: true)
                }
            }
        }
        .padding(.top, 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var widgetHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: 8) {
                Text(content.locationName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 8)

                WeatherGlyph(condition: content.currentCondition, size: 22)
            }

            HStack(spacing: 7) {
                Text("\(content.currentTemperatureText) • \(content.currentSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            if let supplement = content.supplement {
                Label(supplement.text, systemImage: supplement.kind.symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(WidgetTheme.glassPill, in: Capsule())
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel("\(supplement.kind.title), \(supplement.text)")
            }
        }
    }
}

private struct LargeForecastWidgetView: View {
    let content: WidgetWeatherContent
    let maxDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                widgetHeader
                HStack(spacing: 8) {
                    ForEach(content.dailyForecast.prefix(maxDays)) { day in
                        WidgetForecastColumn(day: day)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                if let warning = content.primaryWarning {
                    warningBlock(warning)
                } else if let snippet = content.forecastSnippet, !snippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    forecastSnippetBlock(title: content.forecastSnippetTitle, body: snippet)
                }

                Text(content.detailText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var widgetHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(content.locationName)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(content.currentTemperatureText) • \(content.currentSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let supplement = content.supplement {
                    Label(supplement.text, systemImage: supplement.kind.symbol)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)
            WeatherGlyph(condition: content.currentCondition, size: 24)
        }
    }

    private func warningBlock(_ warning: WidgetWarningSummary) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(warning.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(warning.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(warning.area)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(warning.color.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.30), lineWidth: 1)
                }
        )
    }

    private func forecastSnippetBlock(title: String?, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(body)
                .font(.caption)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct WidgetForecastColumn: View {
    let day: WidgetForecastDay
    var isCompact = false

    var body: some View {
        VStack(spacing: isCompact ? 3 : 6) {
            Text(day.weekday)
                .font((isCompact ? Font.caption2 : .caption2).weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            WeatherGlyph(condition: day.condition, size: isCompact ? 17 : 20)

            Text(day.maxTemperatureText)
                .font(.caption.weight(.semibold))
            Text(day.minTemperatureText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, isCompact ? 4 : 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 14 : 16, style: .continuous)
                .fill(WidgetTheme.tile)
                .overlay {
                    RoundedRectangle(cornerRadius: isCompact ? 14 : 16, style: .continuous)
                        .stroke(WidgetTheme.tileBorder, lineWidth: 1)
                }
        )
    }
}

private enum WidgetTheme {
    static let deepBlue = Color(red: 0.07, green: 0.28, blue: 0.48)
    static let skyBlue = Color(red: 0.16, green: 0.52, blue: 0.82)
    static let aqua = Color(red: 0.34, green: 0.82, blue: 0.88)
    static let glassEdge = Color.white.opacity(0.34)
    static let border = skyBlue.opacity(0.24)
    static let tileBorder = Color.white.opacity(0.24)
    static let glassPill = LinearGradient(
        colors: [
            Color.white.opacity(0.22),
            aqua.opacity(0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let tile = LinearGradient(
        colors: [
            Color.white.opacity(0.20),
            aqua.opacity(0.13),
            deepBlue.opacity(0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let background = LinearGradient(
        colors: [
            skyBlue.opacity(0.74),
            aqua.opacity(0.48),
            deepBlue.opacity(0.64)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let glassHighlight = LinearGradient(
        colors: [
            Color.white.opacity(0.24),
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private extension View {
    @ViewBuilder
    func widgetContainerBackground(condition: WidgetWeatherCondition) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) {
                WidgetGlassBackground(condition: condition)
            }
        } else {
            padding(0)
                .background(WidgetGlassBackground(condition: condition))
        }
    }
}

private struct WidgetGlassBackground: View {
    let condition: WidgetWeatherCondition

    private var skyColors: [Color] {
        switch condition {
        case .clear, .partlyCloudy: return [Color(red: 0.12, green: 0.34, blue: 0.53), Color(red: 0.08, green: 0.18, blue: 0.29)]
        case .rain, .heavyRain, .storm: return [Color(red: 0.13, green: 0.24, blue: 0.36), Color(red: 0.04, green: 0.10, blue: 0.19)]
        case .snow: return [Color(red: 0.32, green: 0.42, blue: 0.54), Color(red: 0.10, green: 0.19, blue: 0.30)]
        default: return [Color(red: 0.25, green: 0.33, blue: 0.42), Color(red: 0.08, green: 0.15, blue: 0.24)]
        }
    }
    var body: some View {
        ZStack {
            LinearGradient(colors: skyColors, startPoint: .topLeading, endPoint: .bottomTrailing)

            WidgetTheme.glassHighlight
                .blendMode(.screen)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(WidgetTheme.glassEdge, lineWidth: 1)
                .padding(1)
        }
    }
}

struct ArsoWidgetPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ArsoWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            ArsoWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            ArsoWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}

private extension ArsoWidgetEntry {
    static let placeholder = ArsoWidgetEntry(date: .now, content: .placeholder)
}
