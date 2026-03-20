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
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }
}

struct ArsoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ArsoWidgetEntry

    var body: some View {
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
}

struct ArsoCurrentWidget: Widget {
    let kind = "ArsoCurrentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArsoWidgetProvider()) { entry in
            ArsoWidgetEntryView(entry: entry)
                .applyWidgetBackground()
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
                .applyWidgetBackground()
        }
        .configurationDisplayName("ARSO 5 dni")
        .description("Petdnevna grafična napoved za izbrano lokacijo.")
        .supportedFamilies([.systemMedium])
    }
}

struct ArsoForecastLargeWidget: Widget {
    let kind = "ArsoForecastLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArsoWidgetProvider()) { entry in
            ArsoWidgetEntryView(entry: entry)
                .applyWidgetBackground()
        }
        .configurationDisplayName("ARSO podrobno")
        .description("Petdnevna napoved, opozorila in kratek uporaben povzetek.")
        .supportedFamilies([.systemLarge])
    }
}

private struct SmallCurrentWidgetView: View {
    let content: WidgetWeatherContent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.locationName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(content.isFallbackLocation ? "Privzeta lokacija" : "Trenutna lokacija")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                WeatherGlyph(condition: content.currentCondition, size: 28)
            }

            Spacer(minLength: 0)

            Text(content.currentTemperatureText)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.75)

            Text(content.currentSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct MediumForecastWidgetView: View {
    let content: WidgetWeatherContent
    let maxDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            widgetHeader
            HStack(spacing: 8) {
                ForEach(content.dailyForecast.prefix(maxDays)) { day in
                    WidgetForecastColumn(day: day)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
            }

            Spacer(minLength: 8)
            WeatherGlyph(condition: content.currentCondition, size: 24)
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

    var body: some View {
        VStack(spacing: 6) {
            Text(day.weekday)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            WeatherGlyph(condition: day.condition, size: 20)

            Text(day.maxTemperatureText)
                .font(.caption.weight(.semibold))
            Text(day.minTemperatureText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    @ViewBuilder
    func applyWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(.fill.tertiary, for: .widget)
        } else {
            padding()
                .background()
        }
    }
}

#Preview("Small", as: .systemSmall) {
    ArsoCurrentWidget()
} timeline: {
    ArsoWidgetEntry(date: .now, content: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    ArsoForecastMediumWidget()
} timeline: {
    ArsoWidgetEntry(date: .now, content: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    ArsoForecastLargeWidget()
} timeline: {
    ArsoWidgetEntry(date: .now, content: .placeholder)
}
