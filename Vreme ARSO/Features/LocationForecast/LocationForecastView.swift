import Combine
import SwiftUI

struct LocationForecastView: View {
    let container: AppContainer
    let location: ResolvedForecastLocation
    @StateObject private var viewModel: LocationForecastViewModel

    init(container: AppContainer, location: ResolvedForecastLocation) {
        self.container = container
        self.location = location
        _viewModel = StateObject(wrappedValue: LocationForecastViewModel(container: container, location: location))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.report == nil && viewModel.fallbackSections.isEmpty {
                LoadingStateView(title: "Nalagam dnevno napoved …")
            } else if let report = viewModel.report {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        reportHeader(report)

                        LazyVStack(spacing: 12) {
                            ForEach(report.days) { day in
                                ForecastDayCard(
                                    day: day,
                                    iconProvider: container.weatherIconProvider
                                )
                            }
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .appScreenBackground()
            } else if !viewModel.fallbackSections.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        fallbackHeader

                        ForEach(viewModel.fallbackSections) { section in
                            CardSection(title: section.title, systemImage: "text.alignleft") {
                                Text(section.body)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let issuedAt = section.issuedAt {
                                    Text("Objavljeno: \(DateFormatterSI.displayDateTime.string(from: issuedAt))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .appScreenBackground()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else {
                ContentUnavailableView("Dnevna napoved ni na voljo", systemImage: "calendar")
            }
        }
        .navigationTitle("Napoved po dnevih")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
        .appScreenBackground()
    }

    private func reportHeader(_ report: LocationDailyForecastReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(report.locationName)
                .font(.title2.weight(.semibold))

            if let detail = report.resolvedLocationName, detail != report.locationName {
                Text("Izbrana lokacija: \(detail)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Label("10-dnevni prikaz", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SourceBadge()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private var fallbackHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(location.displayName)
                .font(.title2.weight(.semibold))
            Text("Grafični dnevni prikaz za to lokacijo trenutno ni dosegljiv, zato prikazujemo uradno ARSO tekstovno napoved.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            SourceBadge()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }
}

private struct ForecastDayCard: View {
    let day: LocationDailyForecastDay
    let iconProvider: WeatherIconProvider

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "d. MMMM"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weekdayTitle)
                        .font(.headline)
                    Text(dateTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                WeatherSymbolView(
                    condition: iconProvider.condition(forSymbol: day.weatherSymbol, description: day.summary),
                    size: 28
                )

                VStack(alignment: .trailing, spacing: 2) {
                    Text(NumberFormatterSI.string(from: day.maxTemperature, suffix: "°C"))
                        .font(.title3.weight(.semibold))
                    Text("Min \(NumberFormatterSI.string(from: day.minTemperature, suffix: "°C"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(day.summary.capitalizedSentence)
                .font(.body.weight(.medium))

            HStack(spacing: 10) {
                if let windDescription = day.windDescription?.nilIfBlank {
                    ForecastChip(systemImage: "wind", text: windDescription)
                }

                if let precipitation = day.precipitationAmount {
                    ForecastChip(
                        systemImage: "drop",
                        text: NumberFormatterSI.string(from: precipitation, suffix: "mm")
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private var weekdayTitle: String {
        guard let date = day.date else { return "Brez datuma" }
        let value = Self.weekdayFormatter.string(from: date)
        return value.capitalizedSentence
    }

    private var dateTitle: String {
        guard let date = day.date else { return "Ni podatka" }
        return Self.dateFormatter.string(from: date)
    }
}

private struct ForecastChip: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.Colors.groupedBackground)
            )
    }
}

@MainActor
final class LocationForecastViewModel: ObservableObject {
    @Published private(set) var report: LocationDailyForecastReport?
    @Published private(set) var fallbackSections: [ForecastTextSection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer
    private let location: ResolvedForecastLocation

    init(container: AppContainer, location: ResolvedForecastLocation) {
        self.container = container
        self.location = location
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        async let sectionsTask = container.forecastTextService.fetchSections()

        do {
            let nextReport = try await container.locationForecastService.fetchDailyForecast(for: location)
            let sections = (try? await sectionsTask) ?? []

            report = nextReport
            fallbackSections = fallbackCandidates(from: sections)
            errorMessage = nil
        } catch {
            let sections = (try? await sectionsTask) ?? []
            let fallback = fallbackCandidates(from: sections)

            report = nil
            fallbackSections = fallback
            errorMessage = fallback.isEmpty ? error.localizedDescription : nil
        }
    }

    private func fallbackCandidates(from sections: [ForecastTextSection]) -> [ForecastTextSection] {
        sections.filter {
            $0.type == .petDoDesetDni || $0.type == .obeti
        }
    }
}

private extension String {
    var capitalizedSentence: String {
        prefix(1).uppercased() + dropFirst()
    }
}
