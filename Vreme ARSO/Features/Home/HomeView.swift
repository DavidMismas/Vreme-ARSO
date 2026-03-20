import Combine
import CoreLocation
import SwiftUI

struct HomeView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService
    @StateObject private var viewModel: HomeViewModel

    init(container: AppContainer, settingsStore: SettingsStore, locationService: LocationService) {
        self.container = container
        self.settingsStore = settingsStore
        self.locationService = locationService
        _viewModel = StateObject(wrappedValue: HomeViewModel(container: container))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.state == nil {
                    HomeSkeletonView()
                } else if let state = viewModel.state {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            heroSection(state)
                            metricsSection(state)
                            forecastSection(state)

                            if let warning = state.primaryWarning {
                                warningSection(warning)
                            }

                            imagerySection(state)
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await load()
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorStateView(message: errorMessage) {
                        Task { await load() }
                    }
                } else {
                    ContentUnavailableView("Ni podatkov", systemImage: "cloud.slash")
                }
            }
            .navigationTitle("Vreme ARSO")
            .animation(.easeInOut(duration: 0.22), value: viewModel.state?.location.displayName)
            .task {
                await load()
                locationService.requestAccessIfNeeded()
                locationService.refreshLocation()
            }
            .onChange(of: settingsStore.useCurrentLocation) { _, _ in
                Task { await load() }
            }
            .onChange(of: settingsStore.selectedStationID) { _, _ in
                Task { await load() }
            }
            .onChange(of: settingsStore.manualLocationName) { _, _ in
                Task { await load() }
            }
            .onChange(of: settingsStore.manualLocationLatitude) { _, _ in
                Task { await load() }
            }
            .onChange(of: locationService.currentLocation) { _, _ in
                Task { await load() }
            }
        }
    }

    private func load() async {
        await viewModel.load(
            settings: settingsStore,
            currentLocation: locationService.currentLocation
        )
    }

    private func heroSection(_ state: HomeViewModel.State) -> some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(state.location.displayName)
                        .font(.title2.weight(.semibold))

                    if let detailText = state.location.detailText {
                        Text(detailText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(NumberFormatterSI.string(from: state.observation.temperature, suffix: "°C"))
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    WeatherSymbolView(condition: state.condition, size: 34)
                        .padding(.bottom, 8)
                }

                Text(state.observation.weatherDescription ?? "Brez opisa")
                    .font(.title3.weight(.medium))

                HStack(spacing: 10) {
                    if let timestamp = state.observation.timestamp {
                        Label(DateFormatterSI.displayDateTime.string(from: timestamp), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    SourceBadge()
                }

                NavigationLink {
                    LocationForecastView(container: container, location: state.location)
                } label: {
                    Label("Napoved po dnevih", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.Colors.groupedBackground)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private func metricsSection(_ state: HomeViewModel.State) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            HeroMetricCard(
                title: "Veter",
                value: windText(state.observation),
                systemImage: "wind"
            )
            HeroMetricCard(
                title: "Padavine",
                value: NumberFormatterSI.string(from: state.observation.precipitation, suffix: "mm"),
                systemImage: "drop"
            )
            HeroMetricCard(
                title: "Vlaga",
                value: state.observation.humidity.map { "\($0) %" } ?? "Ni podatka",
                systemImage: "humidity"
            )
            HeroMetricCard(
                title: "Tlak",
                value: NumberFormatterSI.string(from: state.observation.pressure, suffix: "hPa"),
                systemImage: "gauge.with.dots.needle.33percent"
            )
        }
    }

    private func forecastSection(_ state: HomeViewModel.State) -> some View {
        CardSection(title: "Napoved", systemImage: "text.alignleft") {
            Text(state.summaryForecast?.body ?? "Napoved trenutno ni na voljo.")
                .font(.body)

            if let issuedAt = state.summaryForecast?.issuedAt {
                Text("Objavljeno: \(DateFormatterSI.displayDateTime.string(from: issuedAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            NavigationLink("Odpri tekstovno napoved") {
                ForecastTextView(container: container)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.top, 4)
        }
    }

    private func warningSection(_ warning: WarningItem) -> some View {
        NavigationLink {
            WarningsView(container: container)
        } label: {
            CardSection(title: "Opozorila", systemImage: "exclamationmark.triangle") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(warning.title)
                        .font(.headline)
                        .foregroundStyle(warning.severity.color)

                    Text(warning.area)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(warning.body)
                        .font(.subheadline)
                        .lineLimit(3)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func imagerySection(_ state: HomeViewModel.State) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prikazi")
                .font(.title3.weight(.semibold))

            NavigationLink {
                RadarView(container: container)
            } label: {
                ImageryPreviewCard(
                    title: "Radar padavin",
                    subtitle: state.radarPreview?.timestamp.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Zadnji prikaz",
                    imageURL: state.radarPreview?.imageURL,
                    cache: container.imageCacheService,
                    systemImage: "dot.radiowaves.left.and.right"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                SatelliteView(container: container)
            } label: {
                ImageryPreviewCard(
                    title: "Satelit",
                    subtitle: state.satellitePreview?.timestamp.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Zadnja slika",
                    imageURL: state.satellitePreview?.imageURL,
                    cache: container.imageCacheService,
                    systemImage: "globe.europe.africa"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func windText(_ observation: CurrentObservation) -> String {
        let speed = NumberFormatterSI.string(from: observation.windSpeed, suffix: "m/s")
        if let direction = observation.windDirection {
            return "\(direction), \(speed)"
        }
        return speed
    }
}

private struct HeroMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }
}

private struct ImageryPreviewCard: View {
    let title: String
    let subtitle: String
    let imageURL: URL?
    let cache: ImageCacheService
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            preview

            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Odpri prikaz")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    @ViewBuilder
    private var preview: some View {
        Group {
            if let imageURL {
                RemoteCachedImage(url: imageURL, cache: cache, contentMode: .fill)
            } else {
                Color.secondary.opacity(0.08)
                    .overlay {
                        Image(systemName: systemImage)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 116, height: 84)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    struct State {
        let location: ResolvedForecastLocation
        let observation: CurrentObservation
        let condition: WeatherCondition
        let summaryForecast: ForecastTextSection?
        let primaryWarning: WarningItem?
        let radarPreview: RadarFrame?
        let satellitePreview: SatelliteFrame?
    }

    @Published private(set) var state: State?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func load(settings: SettingsStore, currentLocation: CLLocation?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let preference = LocationPreferenceSnapshot(
                useCurrentLocation: settings.useCurrentLocation,
                selectedStationID: settings.selectedStationID,
                manualLocationName: settings.manualLocationName,
                manualCoordinate: settings.manualCoordinate
            )

            async let stationsTask = container.stationsService.fetchStations()
            async let observationsTask = container.currentWeatherService.fetchCurrentObservations()
            async let forecastTask = container.forecastTextService.fetchSections()
            async let warningsTask = container.warningsService.fetchWarnings()
            async let radarTask = container.radarService.fetchFrames()
            async let satelliteTask = container.satelliteService.fetchLatestFrame()

            let stations = try await stationsTask
            let observations = try await observationsTask
            let resolvedLocation = await container.locationResolver.resolve(
                preference: preference,
                currentLocation: currentLocation,
                stations: stations,
                observations: observations
            )

            guard let resolvedLocation else {
                throw ARSOError.parsingFailed("Za izbrano lokacijo trenutno ni vremenskih podatkov.")
            }

            let locationConditions = try? await container.locationForecastService.fetchCurrentConditions(for: resolvedLocation)
            let stationFallbackObservation = resolvedLocation.observation ?? observations.first
            let observation = mergedObservation(
                primary: locationConditions?.observation,
                fallback: stationFallbackObservation,
                fallbackStationID: resolvedLocation.nearestStation?.id ?? resolvedLocation.displayName
            )

            guard let observation else {
                throw ARSOError.parsingFailed("Za izbrano lokacijo trenutno ni vremenskih podatkov.")
            }

            let displayLocation = ResolvedForecastLocation(
                displayName: locationConditions?.locationName ?? resolvedLocation.displayName,
                detailText: resolvedLocation.detailText,
                source: resolvedLocation.source,
                coordinate: resolvedLocation.coordinate,
                nearestStation: resolvedLocation.nearestStation,
                observation: observation
            )

            let forecastSections = (try? await forecastTask) ?? []
            let warnings = (try? await warningsTask) ?? []
            let radarFrames = (try? await radarTask) ?? []
            let satelliteFrame = try? await satelliteTask
            let previewURLs = [radarFrames.last?.imageURL, radarFrames.first?.imageURL, satelliteFrame?.imageURL]
                .compactMap { $0 }

            let nextState = State(
                location: displayLocation,
                observation: observation,
                condition: container.weatherIconProvider.condition(for: observation),
                summaryForecast: forecastSections.first(where: { $0.type == .napoved }),
                primaryWarning: warnings.sorted(by: { $0.severity > $1.severity }).first,
                radarPreview: radarFrames.last ?? radarFrames.first,
                satellitePreview: satelliteFrame
            )

            withAnimation(.easeInOut(duration: 0.22)) {
                state = nextState
            }
            errorMessage = nil
            Task {
                await container.imageCacheService.preload(urls: previewURLs)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func mergedObservation(
        primary: CurrentObservation?,
        fallback: CurrentObservation?,
        fallbackStationID: String
    ) -> CurrentObservation? {
        guard primary != nil || fallback != nil else { return nil }

        return CurrentObservation(
            stationID: primary?.stationID ?? fallback?.stationID ?? fallbackStationID,
            timestamp: primary?.timestamp ?? fallback?.timestamp,
            temperature: primary?.temperature ?? fallback?.temperature,
            apparentTemperature: primary?.apparentTemperature ?? fallback?.apparentTemperature,
            humidity: primary?.humidity ?? fallback?.humidity,
            pressure: primary?.pressure ?? fallback?.pressure,
            windSpeed: primary?.windSpeed ?? fallback?.windSpeed,
            windGust: primary?.windGust ?? fallback?.windGust,
            windDirection: primary?.windDirection ?? fallback?.windDirection,
            windDirectionDegrees: primary?.windDirectionDegrees ?? fallback?.windDirectionDegrees,
            precipitation: primary?.precipitation ?? fallback?.precipitation,
            cloudiness: primary?.cloudiness ?? fallback?.cloudiness,
            weatherSymbol: primary?.weatherSymbol ?? fallback?.weatherSymbol,
            weatherDescription: primary?.weatherDescription ?? fallback?.weatherDescription,
            visibilityKilometers: primary?.visibilityKilometers ?? fallback?.visibilityKilometers,
            source: primary?.source ?? fallback?.source ?? "ARSO"
        )
    }
}

#Preview {
    HomeView(container: .live, settingsStore: SettingsStore(), locationService: LocationService())
}
